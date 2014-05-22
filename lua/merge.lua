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
function getUpdates(rcy, vsx)
	local rsy_list = rs_table[rcy]
	for k,rsy in pairs(rsy_list) do
		getUpdatesFromOneShard(rcy, rsy)
	end
end

function getUpdatesFromOneShard(rcy, rsy)
	--get index list from shard
	local cmd = "redis-cli -h "..rcy.." -p "..rsy.." lrange index:"..rc..":"..rs.." 0 -1"
	local index_list = split(run(cmd), "\n")
	for i,index in ipairs(index_list) do
		--format like this
		--t:rc.rs.id
		local t = split(index, ":")[1]
		local element = split(index, ":")[2]

		--if element is new, get it;else, jump out of the loop
		--if 
		--vxs
		--get element from shard
		--getElementFromOneShard(rcy, rsy, element)
	end
end

function getElementFromOneShard( ... )
	local cmd2 = "redis-cli -h "..rcy.." -p "..rsy.." lrange index:"..rc..":"..rs.." 0 -1"
	local index_list = split(run(cmd), "\n")
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
	local timestamp_y = getVersion(timestamp, other_rc)

	local tx_serialized = serialize(timestamp_x)
	--After eval transfer, space will make a mess, and quatation will automatically be deleted.
	--So here, we use some methods to take care of it.
	tx_serialized = tx_serialized:gsub(" ", "")
	tx_serialized = tx_serialized:gsub("\"", "_")

	--In order to enable serialize, I put the serialize_local.lua together
	local cmd = "redis-cli -h localhost -p 6380 eval \"$(cat serialize_local.lua merge_get_updates.lua)\" 0 "..tx_serialized
	local res = run(cmd)
	res = split(res, "\n")[1]
	
	--[[res = res:gsub("_", "\"")
	res = loadstring(res)()]]--

	print(res)

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

mergeToLocalClusterFromAllOthers(local_rc, rc_list, rs_list)



