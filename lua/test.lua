function run(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	return result
end

function getInstancePort()
	local res = run("redis-cli config get port")
	local port = string.split(res, "\n")[2]
	return port
end

function getInstanceIp()
	local res = run("ifconfig")
	--local port = string.split(res, "\n")[2]
	return res
end


function split(s, p)

    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt

end 

function testf1()
	return 1,2
end

function serialize(s)
	return "abc"
end

a = {}
a['a1'] = 1
print(a['a1'])



--local res = os.execute("redis-cli eval \"$(cat lookup.lua)\" 0 xiong")
--local cmd2 = "redis-cli -h localhost -p 6380 eval \"$(cat lookup.lua)\" 0 xiong"
--cmd2 = "redis-cli -h ".."localhost".." -p ".."6379".." config get port"
--local cmd2 = "ls"

--local res = run(cmd2)
--print(getInstanceIp())
