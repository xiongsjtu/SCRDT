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

rc_list = {"192.168.0.123", "192.168.0.124"}
rs_list = {}
rs_list["192.168.0.123"] = {"6379"}
rs_list["192.168.0.124"] = {"6379"}


for i,rc in ipairs(rc_list) do
	for i,rs in ipairs(rs_list[rc]) do
		cmd0 = "redis-cli -h "..rc.." -p "..rs.." flushdb"
		run(cmd0)

		cmd1 = "redis-cli -h "..rc.." -p "..rs.." set local_rc "..rc
		run(cmd1)

		cmd2 = "redis-cli -h "..rc.." -p "..rs.." set local_rs "..rs
		run(cmd2)

		cmd3 = "redis-cli -h "..rc.." -p "..rs.." sadd rc_list"
		for i,rc2 in ipairs(rc_list) do
			cmd3 = cmd3.." "..rc2
		end
		run(cmd3)
		
		for i,rc3 in ipairs(rc_list) do
			cmd4 = "redis-cli -h "..rc.." -p "..rs.." sadd rs_list:"..rc3
			for i,rs2 in ipairs(rs_list[rc3]) do
				cmd4 = cmd4.." "..rs2
			end
			run(cmd4)
		end
	end
end
