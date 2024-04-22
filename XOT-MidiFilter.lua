this.inlets = 1
this.outlets = 3

-- scripts

gatescript = 'false'
notescript = '60'
velocityscript = '60'
lengthscript = '40'
delayscript = '0'
statescript = '0'

function setgatescript(s)
    gatescript = s
end

function setnotescript(s)
    notescript = s
end

function setvelocityscript(s)
    velocityscript = s
end

function setlengthscript(s)
    lengthscript = s
end

function setdelayscript(s)
    delayscript = s
end

function setstatescript(s)
    statescript = s
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

-- state

S = 0 -- current state
NS = 0 -- next state
t = 0 -- tick count
i = 0 -- note index
L = 0 -- no. of note in current chord
N = {} -- current chord notes (0..l-1)
V = {} -- current chord velocities (0..l-1)

function reset(v)
	L = 0
	N = {}
	V = {}
	t = 0
	S = 0
	NS = 0
	math.randomseed(os.time())
	tick(0)
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
    print('length: ',L)
    for j=0,L-1 do
        print(N[j],' ; ',V[j])
    end
end

function tick(x)
	local sf = loadstring("return " .. statescript)
	local gf = loadstring("return " .. gatescript)
	local nf = loadstring("return " .. notescript)
	local vf = loadstring("return " .. velocityscript)
	local lf = loadstring("return " .. lengthscript)
	local df = loadstring("return " .. delayscript)
	NS = sf()
	for j=0,L-1 do
		i = j
		if gf() then 
			delay = df()
			outlet(0,math.floor(nf()),math.floor(vf()))
			outlet(1,math.floor(delay))
			outlet(2,math.floor(lf()+delay))
		end
	end
	t = t+1
	S = NS
end