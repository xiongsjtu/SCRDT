
--int argv
local tx_serialized = ARGV[1]
--After eval transfer, space will make a mess, and quatation will automatically be deleted.
--So here, we use some methods to take care of it.
tx_serialized = tx_serialized:gsub("_", "\"")
local timestamp_x = loadstring(tx_serialized)()




--After eval transfer, space will make a mess, and quatation will automatically be deleted.
--So here, we use some methods to take care of it.
local b = serialize(timestamp_x)
b = b:gsub(" ", "")
b = b:gsub("\"", "_")


return timestamp_x['192.168.0.123']