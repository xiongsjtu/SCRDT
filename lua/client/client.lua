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

function arraySize(array)
	local size = 0
	for i,v in pairs(array) do
		size = size +1
	end
	return size
end

--hash function
--an easy impl:just assume e is a number, and divide the rs_count by it
function hash(e, rs_list)
	--get length of list
	local rs_count = arraySize(rs_list)

	return rs_list[e%rs_count+1]
end

--first get rc and rs information from localhost
local_ip = "localhost"
local_port = 6379
client_rc = split(run("redis-cli -h "..local_ip.." -p "..local_port
	.." get client_rc"), '\n')[0]
client_rs_list = split(run("redis-cli -h "..local_ip.." -p "..local_port
	.." smembers client_rs_list"), '\n')

if (client_rc == nil) then
	--if not exists, get rc and rs information from coordinator server
	coordinator_ip = "192.168.0.123"
	coordinator_port = 6379
	rc_list = split(run("redis-cli -h "..coordinator_ip.." -p "..coordinator_port
		.." smembers rc_list"), '\n')

	--pick an rc randomly
	math.randomseed(os.time())
	client_rc = rc_list[math.random(arraySize(rc_list))]

	client_rs_list = split(run("redis-cli -h "..coordinator_ip.." -p "..coordinator_port
		.." smembers rs_list:"..client_rc), '\n')

	--save the client_rc and client_rs_list into local redis
	run("redis-cli -h "..local_ip.." -p "..local_port
		.." set client_rc "..client_rc)
	--expire the local rc
	run("redis-cli -h "..local_ip.." -p "..local_port
		.." expire client_rc "..60)

	cmd = "redis-cli -h "..local_ip.." -p "..local_port
		.." sadd client_rs_list"
	for k,rs in pairs(client_rs_list) do
		cmd = cmd.." "..rs
	end
	run(cmd)
end


ttl = 3600
--init arg
op = arg[1]
e = arg[2]
client_rs = hash(e, client_rs_list)

if op == 'add' then
	cmd = "redis-cli -h "..client_rc.." -p "..client_rs
			.." eval \"$(cat add.lua)\" 0 "
			..e.." "..client_rc.." "..client_rs.." "..ttl
	print(cmd)
	print(run(cmd))
elseif op == 'remove' then
	cmd = "redis-cli -h "..client_rc.." -p "..client_rs
		.." eval \"$(cat remove.lua)\" 0 "
		..e.." "..client_rc.." "..client_rs.." "..ttl
	print(cmd)
	print(run(cmd))
elseif op == 'lookup' then
	cmd = "redis-cli -h "..client_rc.." -p "..client_rs
		.." eval \"$(cat lookup.lua)\" 0 "
		..e
	print(cmd)
	print(run(cmd))
end




