this.inlets = 1
this.outlets = 4 -- note on, delay on, note off, delay off

-- state

S = 0 -- current state
NS = 0 -- next state
t = 0 -- tick count
i = 0 -- note index
L = 0 -- no. of note in current chord
N = {} -- current chord notes (0..l-1)
N[0] = 0
V = {} -- current chord velocities (0..l-1)

function reset(v)
    L = 0
    N = {}
    N[0] = 0
    V = {}
    t = 0
    S = 0
    NS = 0
    math.randomseed(os.time())
    tick(0)
end

-- parameters

p1 = 0
p2 = 0
p3 = 0

function setp1(v)
    p1 = v
end 

function setp2(v)
    p2 = v
end 

function setp3(v)
    p3 = v
end 

-- scripts

gf = loadstring("return false")
nf = loadstring("return 0")
vf = loadstring("return 0")
lf = loadstring("return 0")
df = loadstring("return 0")
sf = loadstring("return 0")

function setgatescript(s)
    gf = loadstring("return " .. s)
end

function setnotescript(s)
    nf = loadstring("return " .. s)
end

function setvelocityscript(s)
    vf = loadstring("return " .. s)
end

function setlengthscript(s)
    lf = loadstring("return " .. s)
end

function setdelayscript(s)
    df = loadstring("return " .. s)
end

function setstatescript(s)
    sf = loadstring("return " .. s)
end

-- auxiliary

function b(v) -- convert bool to 0,1
   if v then
      return 1
   else
      return 0
   end
end

-- euclidean rhythm: n steps, p beats, rotated r, i-th index
-- from  https://paulbatchelor.github.io/sndkit/euclid/
function e(n,p,r,i) 
    -- return ((p * (i + r)) % n) < p 
    return (((p * (i + r + 1)) % n) + p) >= n
end

function r()
    return math.random(0,100)
end

function div(n,d)
    return math.floor(n/d)
end

-- process incoming messages

-- MIDI note on/off
function list(note,velocity)
    k = 0
    while (k < L) and (N[k] < note) do
        k=k+1
    end
    if (velocity ~= 0) and ((k == L) or (N[k] ~= note)) then -- insert
        for j=L-1,k,-1 do
            N[j+1]=N[j]
            V[j+1]=V[j]
        end
	L=L+1
	N[k]=note
	V[k]=velocity
    elseif (velocity == 0) and (k < L) and (N[k] == note) then -- delete
        for j=k,L-1 do
            N[j]=N[j+1]
            V[j]=V[j+1]
        end
        L=L-1        
    end
end

offmap = {} -- record which note off to send for a note on
delaymap = {} -- record which delay to send for a note on

function dotick()
    for j=0, math.max(0,L-1) do -- do it at least once, even if chord is empty
        i = j
        if gf() then 
            note = math.floor(nf())
            velocity = math.floor(vf())
            length = math.floor(lf())            
            delay = math.floor(df())
            outlet(0,note,velocity)
            outlet(1,delay)
            if length > 0 then
                outlet(2,note,0)
                outlet(3,length+delay)
            else
                offmap[N[j]] = note
                delaymap[N[j]] = delay
            end
        else
            offmap[N[j]] = nil
        end
    end
    t = t+1
end

function tick()
    NS = sf()
    dotick()
    S = NS
end

lastvelocitywaszero = true

function notetick(n,v)
    if v ~= 0 then
        if lastvelocitywaszero then
	    NS = sf()
	end
        N[0] = n
        V[0] = v
        L = 1
        dotick() -- if length == 0, then offmap[n] will be set
        if lastvelocitywaszero then
	    S = NS
	end
	lastvelocitywaszero = false
    else
        lastvelocitywaszero = true
        if offmap[n] ~= nil then
             outlet(2,offmap[n],0)
             outlet(3,delaymap[n])
	end
    end
end