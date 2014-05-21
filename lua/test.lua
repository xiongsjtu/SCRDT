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


string.split = function(s, p)

    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt

end 


--local res = os.execute("redis-cli eval \"$(cat lookup.lua)\" 0 xiong")
local cmd2 = "redis-cli -h localhost -p 6380 eval \"$(cat lookup.lua)\" 0 xiong"
--cmd2 = "redis-cli -h ".."localhost".." -p ".."6379".." config get port"
--local cmd2 = "ls"

--local res = run(cmd2)
--print(getInstanceIp())

a = {}
a[1] = {}
a[1][2] = 1
for k,v in pairs(a) do
	print(x)
end