--run cmd and return result
local function run(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	return result
end

-- {1,2,3,4} --> " 1 2 3 4"
local function array2Str(array)
	local str = ""
	for k,v in pairs(array) do
		str = str.." "..v
	end
	return str
end

local function arraySize(array)
	local count = 0
	for k,v in pairs(array) do
		count = count + 1
	end
	return count
end

--config
local rcx = "192.168.0.123"
local rcy = "192.168.0.124"
local rsx_list = {6379, 6380}
local rsy_list = {6379, 6380}

--merge from x to y
--Every shard in cluster x needs to merge to every shard in cluster y
for i,rsx in pairs(rsx_list) do
	local cmd = "redis-cli -h "..rcx.." -p "..rsx..
		" eval \"$(cat merge.lua)\" 0 "..rcx.." "..rcy.." "
		..arraySize(rsx_list)..array2Str(rsx_list).." "
		..arraySize(rsy_list)..array2Str(rsy_list)
	--cmd = "redis-cli -h localhost -p 6379 eval \"$(cat lookup.lua)\" 0 xiong"
	print(cmd)
	print(run(cmd))
end

