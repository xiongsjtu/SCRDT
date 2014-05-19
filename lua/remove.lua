--init argv
local e = ARGV[1] 
local rc2 = ARGV[2]
local rs2 = ARGV[3]
local ttl = ARGV[4]

--remove procedure
local t2 = redis.call("INCR", "timestamp:"..rc2..":"..rs2)
local ids = redis.call("SMEMBERS", "ids:"..e)
for i, gid in pairs(ids) do
	if redis.call("EXISTS", "element:"..gid) == 1 then
		redis.call("HMSET", "element:"..gid, "rmv.t", t2, "rmv.rc", rc2, "rmv.rs", rs2)
		redis.call("expire", "element:"..gid, ttl)
		redis.call("lpush", "index:"..rc2..":"..rs2, t2..":"..gid)
	end
end
