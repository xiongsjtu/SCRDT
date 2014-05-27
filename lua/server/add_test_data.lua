function run(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	return result
end

function split(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

function arraySize(array)
	local size = 0
	for i,v in pairs(array) do
		size = size +1
	end
	return size
end

--hash function
--an easy impl:just assume e is a number, and divide the rs_count by it
function hash(e, rs_list)
	--get length of list
	local rs_count = arraySize(rs_list)

	return rs_list[e%rs_count+1]
end

--main

--init arg
local data_num = arg[1]
local rc = arg[2]
local rs_count = arg[3]
local rs_list = {}
for i=1,rs_count do
	table.insert(rs_list, arg[3+i])
end

--flushdb
for k,rs in pairs(rs_list) do
	run("redis-cli -h "..rc.." -p "..rs.." flushdb")
end

--init local info
local rs_count = arraySize(rs_list)
local cmd1 = "lua server_startup.lua add "..rc.." "..rs_count
for k,rs in pairs(rs_list) do
	cmd1 = cmd1.." "..rs
end
run(cmd1)

--add data uniformly
local ttl = 10
for i=1,data_num do
	local rs = hash(i, rs_list)
	local cmd = "redis-cli -h "..rc.." -p "..rs
			.." eval \"$(cat ../client/op/add.lua)\" 0 "
			..i.." "..rc.." "..rs.." "..ttl
	run(cmd)
end