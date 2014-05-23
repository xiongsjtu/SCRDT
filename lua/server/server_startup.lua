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

function makeChangesToOneShard(rcx, rsx)
	rc = rcx
	rs = rsx
	--refresh rc_list
	run("redis-cli -h "..rc.." -p "..rs
		.." del rc_list")

	cmd1 = "redis-cli -h "..rc.." -p "..rs
		.." sadd rc_list"
	for k,rc2 in pairs(rc_list) do
		cmd1 = cmd1.." "..rc2
	end
	run(cmd1)

	--refresh rs_list
	for k,rc2 in pairs(rc_list) do
		run("redis-cli -h "..rc.." -p "..rs
			.." del rs_list:"..rc2) 
	end

	local cmd2 = "redis-cli -h "..rc.." -p "..rs
		.." sadd rs_list:"
	for k,rc2 in pairs(rc_list) do
		cmd3 = cmd2..rc2
		for k,rs2 in pairs(rs_list[rc2]) do
			cmd3 = cmd3.." "..rs2
		end
		run(cmd3)
	end
end

--init arg
add_or_remove = arg[1]
local_rc = arg[2]

if (add_or_remove == 'add') then
	local_rs_count = arg[3]
	local_rs_list = {}
	for i=1,local_rs_count do
		table.insert(local_rs_list, arg[3+i])
	end
end

--get rc and rs information from coordinator server
coordinator_ip = "192.168.0.123"
coordinator_port = 6379
rc_list = split(run("redis-cli -h "..coordinator_ip.." -p "..coordinator_port
	.." smembers rc_list"), '\n')
rs_list = {}
for i,rc in ipairs(rc_list) do
	rs_list[rc] = split(run("redis-cli -h "..coordinator_ip.." -p "..coordinator_port
	.." smembers rs_list:"..rc), '\n')
end

if add_or_remove == 'remove' then
	--if the operation is remove, then remove the rc and rs in the global
	for i=#rc_list,1,-1 do
	    if rc_list[i] == local_rc then
	        table.remove(rc_list, i)
	    end
	end

	rs_list[local_rc] = {}
else
	--else if the operation is add, add local rc and rs_list into the global rc_list and rs_list
	--if local_rc is not in global rc_list, add it
	rc_is_in_global = false
	for i,rc in ipairs(rc_list) do
		if (rc == local_rc) then
			rc_is_in_global = true
			break
		end
	end
	if rc_is_in_global == false then
		table.insert(rc_list, local_rc)
	end

	--refresh the global rs_list with local_rs_list
	rs_list[local_rc] = local_rs_list

	
	for k,rs in pairs(local_rs_list) do
		--add local_rc to instance of local server
		run("redis-cli -h "..local_rc.." -p "..rs
			.." set local_rc "..local_rc)
	end


end

--make the change to every instance of every other server
for k,rc in pairs(rc_list) do
	for k,rs in pairs(rs_list[rc]) do
		makeChangesToOneShard(rc, rs)
	end
end

--


