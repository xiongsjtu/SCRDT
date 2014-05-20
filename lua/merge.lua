--run cmd and return result
local function run(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	return result
end

--version
local function version(rcx, rsx_list, rcy, rsy_list, rc)
	local T = {}
	if  then
		local max = {}
		for i,rs in ipairs(rs_list) do
			local t = run("redis-cli -h "..rcx.." -p "..getInstancePort().." get timestamp:"..rc..":"..rs)
		end
		
	else
	end
end

local function getInstancePort()
	local res = run("redis-cli config get port")
	local port = string.split(res, "\n")[2]
	return port
end

local string.split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end 


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


return rsy_list[1]