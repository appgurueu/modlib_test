local mod, b3d = modlib.mod, modlib.b3d

local stream = assert(io.open(mod.get_resource("modlib_test", "b3d", "character.b3d"), "rb"))
local character = assert(b3d.read(stream))
stream:close()
local str = character:write_string()
local read = b3d.read(modlib.text.inputstream(str))
assert(modlib.table.equals_noncircular(character, read))
