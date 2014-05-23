
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

--getTimeStamp
local function getTimeStamp(local_rc, local_rs, rc_list, rs_list)
	local ts = {}
	for i,rc in ipairs(rc_list) do
		for j,rs in ipairs(rs_list[rc]) do
			--local cmd = "redis-cli -h "..local_rc.." -p "..local_rs.." get timestamp:"..rc..":"..rs
			local t = redis.call("get", "timestamp:"..rc..":"..rs)--split(run(cmd), "\n")[1]
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
local function getVersion(timestamp, rcx)
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


--main
--init config
--cluster and shard configs will be read from redis
local local_rc = redis.call("get", "local_rc")--read local rc from redis
local local_rs = redis.call("get", "local_rs")--read local rs from redis
local rc_list = redis.call("smembers", "rc_list")--read rc_list from redis
local rs_list = {}--read rs_list from redis
for k,rc in pairs(rc_list) do
	local one_rs_list = redis.call("smembers", "rs_list:"..rc)
	rs_list[rc] = one_rs_list
end

--int argv
local tx_serialized = ARGV[1]
local timestamp_x = unserialize_local(tx_serialized)


--get updates
local AR = {}
for k1,rc in pairs(rc_list) do
	for k2,rs in pairs(rs_list[rc]) do
		--get index:rc:rs
		--local cmd = "redis-cli -h "..local_rc.." -p "..local_rs.." lrange index:"..rc..":"..rs.." 0 -1"
		local index_list = redis.call("lrange", "index:"..rc..":"..rs, "0", "-1")
		for i,index in ipairs(index_list) do
			--format like this
			--t:rc.rs.id
			local t = split(index, ":")[1]
			local rc_rs_id = split(index, ":")[2]
			local rc_in_rri = split(rc_rs_id, ".")[1]
				.."."..split(rc_rs_id, ".")[2]
				.."."..split(rc_rs_id, ".")[3]
				.."."..split(rc_rs_id, ".")[4]
			local rs_in_rri = split(rc_rs_id, ".")[5]
			local id_in_rri = split(rc_rs_id, ".")[6]

			--if element is new, get it
			if timestamp_x[rc_in_rri] == nil or tonumber(timestamp_x[rc_in_rri]) < tonumber(t) then
				-- get element:rc.rs.id
				local element_rc_rs_id = {}
				element_rc_rs_id["value"] = redis.call("hget", "element:"..rc_rs_id, "value")
				element_rc_rs_id["add.t"] = redis.call("hget", "element:"..rc_rs_id, "add.t")
				element_rc_rs_id["add.rc"] = redis.call("hget", "element:"..rc_rs_id, "add.rc")
				element_rc_rs_id["add.rs"] = redis.call("hget", "element:"..rc_rs_id, "add.rs")
				element_rc_rs_id["rmv.t"] = redis.call("hget", "element:"..rc_rs_id, "rmv.t")
				element_rc_rs_id["rmv.rc"] = redis.call("hget", "element:"..rc_rs_id, "rmv.rc")
				element_rc_rs_id["rmv.rs"] = redis.call("hget", "element:"..rc_rs_id, "rmv.rs")
				--element_rc_rs_id["debug.t"] = t
				--element_rc_rs_id["debug.rc_in_rri"] = rc_in_rri
				--element_rc_rs_id["debug.timestamp_x[rc_in_rri]"] = timestamp_x[rc_in_rri]


				--table.insert(AR, element_rc_rs_id)
				AR[index] = element_rc_rs_id
			end
		end
	end
end

--get Ty
local timestamp = getTimeStamp(local_rc, local_rs, rc_list, rs_list)
local timestamp_y = getVersion(timestamp, local_rc)

--get result
local updates = {}
updates['AR'] = AR
updates['T'] = timestamp_y

--serialize and return
local result = serialize_local(updates)


return result