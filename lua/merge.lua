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

--getTimeStamp
function getTimeStamp()
	local ts = {}
	for i,rc in ipairs(rc_list) do
		for j,rs in ipairs(rs_table[rc]) do
			local cmd = "redis-cli -h "..ip.." -p "..port.." get timestamp:"..rc..":"..rs
			local t = split(run(cmd), "\n")[1]
			if (ts[rc] == nil) then
				ts[rc] = {}
			end
			ts[rc][rs] = t
		end
	end
	return ts
end

--version
function getVersion(rcx)
	local vs = {}
	for i,rc in ipairs(rc_list) do
		for j,rs in ipairs(rs_table[rc]) do
			if vs[rc] == nil then
				vs[rc] = T[rc][rs]
			else
				if rcx == rc then
					if vs[rc] < T[rc][rs] then
						vs[rc] = T[rc][rs]
					end
				else
					if vs[rc] > T[rc][rs] then
						vs[rc] = T[rc][rs]
					end
				end
			end
		end
	end
	return vs
end


function getInstancePort()
	local res = run("redis-cli config get port")
	local port = split(res, "\n")[2]
	return port
end


--get delta updates from all shards in cluster y
function getUpdates(rcy)
	local A2 = {}
	local R2 = {}
	local rsy_list = rs_table[rcy]
	for k,rsy in pairs(rsy_list) do
		A2, R2 = getUpdatesFromOneShard(rcy, rsy)
	end
end

function getUpdatesFromOneShard(rcy, rsy)
	--get index list from shard
	local cmd = "redis-cli -h "..rcy.." -p "..rsy.." lrange index:"..rc..":"..rs.." 0 -1"
	local index_list = split(run(cmd), "\n")
	for i,index in ipairs(index_list) do
		--format like this
		--t:rc.rs.id
		local t = split(index, ":")[1]
		local e_desc = split(index, ":")[2]
		local rc_in_ed = split(e_desc, ".")[1]
		local rs_in_ed = split(e_desc, ".")[2]
		local id_in_ed = split(e_desc, ".")[3]

		--if element is new, get it;else, jump out of the loop
		if vsx[rc_in_ed] < 
		vxs
		--get element from shard
		getElementFromOneShard(rcy, rsy, e_desc)
	end
end

function  getElementFromOneShard( ... )
	local cmd2 = "redis-cli -h "..rcy.." -p "..rsy.." lrange index:"..rc..":"..rs.." 0 -1"
	local index_list = split(run(cmd), "\n")
end

--test
ARGV = {"192.168.0.123", "192.168.0.124", '2', 6379, 6380, 3, 6379, 6380, 6381}

--init argv
local rcx = ARGV[1]
local rcy = ARGV[2]
local rsx_count = ARGV[3]
local rsx_list = {}
for i=1,rsx_count do
	table.insert(rsx_list, ARGV[3+i])
end
local rsy_count = ARGV[4+rsx_count]
local rsy_list = {}
for i=1,rsy_count do
	table.insert(rsy_list, ARGV[4+rsx_count+i])
end

--init local var
rc_list = {rcx, rcy}
rs_table = {}
rs_table[rcx] = rsx_list
rs_table[rcy] = rsy_list

ip = "localhost"
port = getInstancePort()

T = getTimeStamp()
vsx = getVersion(rcx)
vsy = getVersion(rcy)


--return rsy_list[1]