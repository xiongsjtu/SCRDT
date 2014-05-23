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

--add
ip = "192.168.0.123"
port = "6379"
rc = "192.168.0.123"
rs = "6379"
for i=1,5 do
	element = i
	run("redis-cli -h "..ip.." -p "..port.." eval \"$(cat add.lua)\" 0 "..element.." "..rc.." "..rs)
end

ip = "192.168.0.124"
port = "6379"
rc = "192.168.0.124"
rs = "6379"
for i=6,10 do
	element = i
	run("redis-cli -h "..ip.." -p "..port.." eval \"$(cat add.lua)\" 0 "..element.." "..rc.." "..rs)
end

ip = "192.168.0.124"
port = "6379"
rc = "192.168.0.123"
rs = "6379"
for i=11,20 do
	element = i
	run("redis-cli -h "..ip.." -p "..port.." eval \"$(cat add.lua)\" 0 "..element.." "..rc.." "..rs)
end

--remove
--[[ip = "192.168.0.123"
port = "6379"
rc = "192.168.0.123"
rs = "6379"
for i=1,3 do
	element = i
	run("redis-cli -h "..ip.." -p "..port.." eval \"$(cat remove.lua)\" 0 "..element.." "..rc.." "..rs)
end

ip = "192.168.0.124"
port = "6379"
rc = "192.168.0.124"
rs = "6379"
for i=6,8 do
	element = i
	run("redis-cli -h "..ip.." -p "..port.." eval \"$(cat remove.lua)\" 0 "..element.." "..rc.." "..rs)
end

ip = "192.168.0.124"
port = "6379"
rc = "192.168.0.123"
rs = "6379"
for i=11,18 do
	element = i
	run("redis-cli -h "..ip.." -p "..port.." eval \"$(cat remove.lua)\" 0 "..element.." "..rc.." "..rs)
end
]]--