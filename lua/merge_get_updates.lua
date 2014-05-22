
--run cmd and return result
local function run(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	return result
end

local function split(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

local function serialize_local(obj)
	-- serialize function is in serialize.lua file, which will be transmitted together with this file
	obj = serialize(obj)
	--After redis-cli eval transfer, space will make a mess, and quatation will automatically be deleted.
	--So here, we use some methods to take care of it.
	obj = obj:gsub(" ", "")
	obj = obj:gsub("\"", "_sjtu_adc_")
	return obj
end

local function unserialize_local(obj)
	--After redis-cli eval transfer, quatation will automatically be deleted.
	--So here, we use some methods to take care of it.
	obj = obj:gsub("_sjtu_adc_", "\"")
	obj = loadstring(obj)()
	return obj
end


--main

--init config
--cluster and shard configs will be read from redis
local local_rc = split(run("redis-cli -h localhost -p 6380 get local_rc"), '\n')[1] -- read local rc from redis
local rc_list = split(run("redis-cli -h localhost -p 6380 smembers rc_list"), '\n') -- read rc_list from redis
local rs_list = {}-- read rs_list from redis
for k,rc in pairs(rc_list) do
	local one_rs_list = split(run("redis-cli -h localhost -p 6380 smembers rs_list:"..rc), '\n')
	rs_list[rc] = one_rs_list
end

--int argv
local tx_serialized = ARGV[1]
local timestamp_x = unserialize_local(tx_serialized)
local local_rs = ARGV[2]


--get index:rc:rs
local AR = {}
for k1,rc in pairs(rc_list) do
	for k2,rs in pairs(rs_list[rc]) do
		local cmd = "redis-cli -h "..local_rc.." -p "..local_rs.." lrange index:"..rc..":"..rs.." 0 -1"
		local index_list = split(run(cmd), "\n")
		for i,index in ipairs(index_list) do
			--format like this
			--t:rc.rs.id
			local t = split(index, ":")[1]
			local rc_rs_id = split(index, ":")[2]
			local rc_in_rri = split(rc_rs_id, ".")[1]
			local rs_in_rri = split(rc_rs_id, ".")[2]
			local id_in_rri = split(rc_rs_id, ".")[3]

			--if element is new, get it;else, jump out of the loop
			if timestamp_x[rc_in_rri] < t then
				-- get element:rc.rs.id
				local element_rc_rs_id = {}
				local cmd2 = "redis-cli -h "..local_rc.." -p "..local_rs.." hget element:"..rc_rs_id
				element_rc_rs_id["value"] = split(run(cmd2.." value"), '\n')[1]
				element_rc_rs_id["add.t"] = split(run(cmd2.." add.t"), '\n')[1]
				element_rc_rs_id["add.rc"] = split(run(cmd2.." add.rc"), '\n')[1]
				element_rc_rs_id["add.rs"] = split(run(cmd2.." add.rs"), '\n')[1]
				element_rc_rs_id["rmv.t"] = split(run(cmd2.." rmv.t"), '\n')[1]
				element_rc_rs_id["rmv.rc"] = split(run(cmd2.." rmv.rc"), '\n')[1]
				element_rc_rs_id["rmv.rs"] = split(run(cmd2.." rmv.rs"), '\n')[1]


				table.insert(AR, )
			else
				break
			end
		end
	end
end


--After eval transfer, space will make a mess, and quatation will automatically be deleted.
--So here, we use some methods to take care of it.
local b = serialize_local(timestamp_x)


return timestamp_x['192.168.0.123']