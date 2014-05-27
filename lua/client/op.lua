require "config"

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


ttl = 3600
--init arg
client_rc = 'localhost'
client_rs = '6379'

--hash function also random cordinator
function cordinator(e)
	math.randomseed(os.time())
        client_rc = rc_list[math.random(#rc_list)]
        client_rs = rs_list[client_rc][string.byte(e)%(#rs_list[client_rc])+1]
	--print(client_rc.." "..client_rs)
end

--op
function add(e)
	cordinator(e)
 	cmd = "redis-cli -h "..client_rc.." -p "..client_rs
		.." eval \"$(cat op/add.lua)\" 0 '"
		..e.."' "..client_rc.." "..client_rs.." "..ttl
        --print(cmd)
        return (run(cmd))

end

function remove(e)
	cordinator(e)
        cmd = "redis-cli -h "..client_rc.." -p "..client_rs
                .." eval \"$(cat op/remove.lua)\" 0 '"
                ..e.."' "..client_rc.." "..client_rs.." "..ttl
        --print(cmd)
        return run(cmd)

end

function lookup(e)
	cordinator(e)
        cmd = "redis-cli -h "..client_rc.." -p "..client_rs
                .." eval \"$(cat op/lookup.lua)\" 0 '"
                ..e.."'"
        --print(cmd)
        return run(cmd)
end




