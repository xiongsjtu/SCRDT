require "op"


local size = arg[1]
local opts = arg[2]
local data = {}
local rand = {}
local time_begin
local time_end

time_begin = os.clock()

math.randomseed(os.time() )
for i = 1, size do
	for j = 1, 32 do
		repeat
			rand[j] = math.random(32, 126);
		until rand[j] ~= 39 and rand[j] ~= 58
	end
	data[i] = string.char(unpack(rand))
end

time_end = os.clock()
print(string.format("generate data: %.2f sec", (time_end - time_begin)))



--operation benchmark

time_begin = os.time()

for i = 1, size do
	add(data[i])
end

time_end = os.time()
print(string.format("add data: %.2f sec", (time_end - time_begin)))

if opts == 'add' then
	os.exit()
end

time_begin = os.time()

for i = 1, size do
        lookup(data[i])
end

time_end = os.time()
print(string.format("lookup data: %.2f sec", (time_end - time_begin)))

time_begin = os.time()

for i = 1, size do
        remove(data[i])
end

time_end = os.time()
print(string.format("remove data: %.2f sec", (time_end - time_begin)))

