local mod, b3d = modlib.mod, modlib.b3d

local stream = assert(io.open(mod.get_resource("modlib_test", "b3d", "character.b3d"), "r"))
local character = assert(b3d.read(stream))
stream:close()
local str = character:write_string()
local read = b3d.read(modlib.text.inputstream(str))
assert(modlib.table.equals_noncircular(character, read))
--! dirty helper method to truncate tables with 10+ number keys
local function _b3d_truncate(table)
	local count = 1
	for key, value in pairs(table) do
		if type(key) == "table" then
			_b3d_truncate(key)
		end
		if type(value) == "table" then
			_b3d_truncate(value)
		end
		count = count + 1
		if type(key) == "number" and count >= 9 and next(table, key) then
			if count == 9 then
				table[key] = "TRUNCATED"
			else
				table[key] = nil
			end
		end
	end
	return table
end
modlib.file.write(mod.get_resource("modlib_test", "b3d", "character.b3d.lua"), "return " .. dump(_b3d_truncate(table.copy(character))))
