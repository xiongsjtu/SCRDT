--init argv
local e = ARGV[1] 
local rc = ARGV[2]
local rs = ARGV[3]
local ttl = ARGV[4]

--add procedure
local t = redis.call("INCR", "timestamp:"..rc..":"..rs)
local id = redis.call("INCR", "element:next.id")
redis.call("HMSET", "element:"..rc.."."..rs.."."..id, "value", e, "add.t", t, "add.rc", rc, "add.rs", rs)
--redis.call("EXPIRE", "element:"..rc.."."..rs.."."..id, ttl)
redis.call("LPUSH", "index:"..rc..":"..rs, t..":"..rc.."."..rs.."."..id)
redis.call("SADD", "ids:"..e, rc.."."..rs.."."..id)

