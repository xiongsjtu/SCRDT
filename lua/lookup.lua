--init argv
local e = ARGV[1]

-- gets multiple fields from a hash as a dictionary
local hmget = function (key, ...)
	if next(arg) == nil then return {} end
	local bulk = redis.call('HMGET', key, unpack(arg))
	local result = {}
	for i, v in ipairs(bulk) do result[ arg[i] ] = v end
	return result
end

-- gets all fields from a hash as a dictionary
local hgetall = function (key)
	local bulk = redis.call('HGETALL', key)
		local result = {}
		local nextkey
		for i, v in ipairs(bulk) do
			if i % 2 == 1 then
				nextkey = v
			else
				result[nextkey] = v
			end
		end
		return result
end

--lookup procedure
local ids = redis.call("SMEMBERS", "ids:"..e)
for i, gid1 in pairs(ids) do
	if redis.call("EXISTS", "element:"..gid1) == 1 then
		local table1 = hmget("element:"..gid1, "add.t", "add.rc", "add.rs", "rmv.t")
		local t1 = table1["add.t"]
		local rc1 = table1["add.rc"]
		local rs1 = table1["add.rs"]
		local t12 = table1["rmv.t"]
		if t12 == false then
			local lookup = 1
			for i, gid2 in pairs(ids) do
				if redis.call("EXISTS", "element:"..gid2) == 1 then
					local table2 = hgetall("element:"..gid2)
					local t2 = table2["add.t"]
					local rc2 = table1["add.rc"]
					local rs2 = table1["add.rs"]
					local t22 = table2["rmv.t"]
					local rc22 = table1["rmv.rc"]
					local rs22 = table1["rmv.rs"]

					if t1 == t2 and rc1 == rc2 and rs1 == rs2 and t22 ~= nil then
						lookup = 0
						break
					end
				end
			end
			if lookup == 1 then
				return 1
			end		
		end
	end
endz
return 0
