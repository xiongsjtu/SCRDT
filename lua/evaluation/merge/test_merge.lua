require "serialize"

--run cmd and return result
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

function serialize_local(obj)
	obj = serialize(obj)
	--After redis-cli eval transfer, space will make a mess, and quatation will automatically be deleted.
	--So here, we use some methods to take care of it.
	obj = obj:gsub(" ", "")
	obj = obj:gsub("\"", "_sjtu_adc_")
	return obj
end

function unserialize_local(obj)
	--After redis-cli eval transfer, quatation will automatically be deleted.
	--So here, we use some methods to take care of it.
	obj = obj:gsub("_sjtu_adc_", "\"")
	obj = loadstring(obj)()
	return obj
end

function mergeToLocalClusterFromAllOthers(local_rc, rc_list, rs_list)
	--do merge to every shard in the local cluster
	for k,local_rs in pairs(rs_list[local_rc]) do
		mergeToLocalShardFromAllOthers(local_rc, local_rs, rc_list, rs_list)
	end
end

function  mergeToLocalShardFromAllOthers(local_rc, local_rs, rc_list, rs_list)
	-- do merge from every shard in every other cluster
	for k1,other_rc in pairs(rc_list) do
		if other_rc ~= local_rc then
			for k2,other_rs in pairs(rs_list[other_rc]) do
				mergeToLocalShardFromOneShard(local_rc, local_rs, other_rc, other_rs, rc_list, rs_list)
			end
		end
	end
end

function mergeToLocalShardFromOneShard(local_rc, local_rs, other_rc, other_rs, rc_list, rs_list)
	local timestamp = getTimeStamp(local_rc, local_rs, rc_list, rs_list)
	local timestamp_x = getVersion(timestamp, local_rc)

	--updates = {"AR":['t:rc.rs.id':{e,t,rc,rs,t2,rc2,rs2},...],"T":[{'rc':t},...]}
	local x1 = os.clock()
	local updates = getUpdates(other_rc, other_rs, timestamp_x)
	local x2 = os.clock()
	print(string.format("getUpdates from "
		..other_rc..":"..other_rs.." to "
		..local_rc..":"..local_rs.." time: %.2f\n", 10*(x2 - x1)))

	x1 = os.clock()
	addUpdates(updates['AR'], local_rc, local_rs, rc_list, rs_list)
	updateTimeStamps(timestamp, updates['T'], rc_list, rs_list)
	x2 = os.clock()
	print(string.format("addUpdates from "
		..other_rc..":"..other_rs.." to "
		..local_rc..":"..local_rs.." time: %.2f\n", 10*(x2 - x1)))

	--print(updates)
end

--getTimeStamp
function getTimeStamp(local_rc, local_rs, rc_list, rs_list)
	local ts = {}
	for i,rc in ipairs(rc_list) do
		for j,rs in ipairs(rs_list[rc]) do
			local cmd = "redis-cli -h "..local_rc.." -p "..local_rs.." get timestamp:"..rc..":"..rs
			local t = split(run(cmd), "\n")[1]
			if (ts[rc] == nil) then
				ts[rc] = {}
			end
			ts[rc][rs] = t
		end
	end
	return ts
end


--version
--according to the algorithm in the paper
function getVersion(timestamp, rcx)
	local version = {}
	for rc,rs_list in pairs(timestamp) do
		for rs,t in pairs(rs_list) do
			if version[rc] == nil then
				version[rc] = timestamp[rc][rs]
			else
				if rcx == rc then
					if version[rc] < timestamp[rc][rs] then
						version[rc] = timestamp[rc][rs]
					end
				else
					if version[rc] > timestamp[rc][rs] then
						version[rc] = timestamp[rc][rs]
					end
				end
			end
		end
	end
	return version
end

--get delta updates from all shards in cluster y
function getUpdates(other_rc, other_rs, timestamp_x)
	local tx_serialized = serialize_local(timestamp_x)
	
	--In order to enable serialize, I put the serialize_local.lua together
	local cmd = "redis-cli -h "..other_rc.." -p "..other_rs.." eval \"$(cat serialize_local.lua merge_get_updates.lua)\" 0 "..tx_serialized
	--local cmd = "redis-cli -h localhost -p 6380 eval \"$(cat serialize_local.lua merge_get_updates.lua)\" 0 "..tx_serialized
	local res = run(cmd)
	res = split(res, "\n")[1]
	res = unserialize_local(res)
	return res
end

--hash function
--an easy impl:just assume e is a number, and divide the rs_count by it
function hash(e, rs_list_of_rc)
	--get length of list
	local rs_count = 0
	for i,v in ipairs(rs_list_of_rc) do
		rs_count = rs_count + 1
	end

	return rs_list_of_rc[e%rs_count+1]
end


--add updates of elements to local shard
--update format:['t:rc.rs.id':{'value':e,'add.t':t,'add_rc':rc,'add_rs':rs,'rmv.t':t2,'rmv.rc':rc2,'rmv.rs':rs2},...]
--false here means for nil
function addUpdates(updates, local_rc, local_rs, rc_list, rs_list)
	--visit every element to find suitable element for this shard
	for index,element in pairs(updates) do
		--index format is 't:rc.rs.id'
		local t = split(index, ":")[1]
		local rc_rs_id = split(index, ":")[2]
		local rc_in_rri = split(rc_rs_id, ".")[1]
			.."."..split(rc_rs_id, ".")[2]
			.."."..split(rc_rs_id, ".")[3]
			.."."..split(rc_rs_id, ".")[4]
		local rs_in_rri = split(rc_rs_id, ".")[5]
		local id_in_rri = split(rc_rs_id, ".")[6]

		local value = element['value']
		local add_t = element['add.t']
		local add_rc = element['add.rc']
		local add_rs = element['add.rs']
		local rmv_t = element['rmv.t']
		local rmv_rc = element['rmv.rc']
		local rmv_rs = element['rmv.rs']

		local rs = hash(value, rs_list[local_rc])
		if local_rs == rs then
			--hmset element:rc.rs.id
			local cmd1 = "redis-cli -h "..local_rc.." -p "..local_rs
				.." hmset element:"..rc_rs_id
				.." value "..value.." add.t "..add_t.." add.rc "..add_rc.." add.rs "..add_rs
			if rmv_t ~= false then
				cmd1 = cmd1.." rmv.t "..rmv_t.." rmv.rc "..rmv_rc.." rmv.rs "..rmv_rs
			end
			run(cmd1)

			--lpush index:rc:rs t:rc.rs.id for add
			run("redis-cli -h "..local_rc.." -p "..local_rs
				.." lpush index:"..add_rc..":"..add_rs
				.." "..add_t..":"..rc_rs_id)
			--lpush index:rc:rs t:rc.rs.id for remove if exists
			if rmv_t ~= false then
				run("redis-cli -h "..local_rc.." -p "..local_rs
					.." lpush index:"..rmv_rc..":"..rmv_rs
					.." "..rmv_t..":"..rc_rs_id)
			end

			--sadd ids:e rc.rs.id
			run("redis-cli -h "..local_rc.." -p "..local_rs
					.." sadd ids:"..value
					.." "..rc_rs_id)

		end

	end
end

--add updates of elements to local shard
--update format:[{'rc':t}},...]
function updateTimeStamps(timestamp, updates, rc_list, rs_list)
	for rc,t in pairs(updates) do
		for k,rs in pairs(rs_list[rc]) do
			if timestamp[rc][rs] == nil or tonumber(timestamp[rc][rs]) < tonumber(t) then
				local cmd = "redis-cli -h localhost -p 6379 set timestamp:"..rc..":"..rs.." "..t
				run(cmd)
			end
		end
	end
end



--main

--init config
--cluster and shard configs will be read from redis
local local_rc = split(run("redis-cli -h localhost -p 6379 get local_rc"), '\n')[1] -- read local rc from redis
local rc_list = split(run("redis-cli -h localhost -p 6379 smembers rc_list"), '\n') -- read rc_list from redis
local rs_list = {}-- read rs_list from redis
for k,rc in pairs(rc_list) do
	local one_rs_list = split(run("redis-cli -h localhost -p 6379 smembers rs_list:"..rc), '\n')
	rs_list[rc] = one_rs_list
end

mergeToLocalClusterFromAllOthers(local_rc, rc_list, rs_list)


