modlib.mod.include"b3d.lua"
modlib.mod.include"tex.lua"
-- Run all tests twice to ensure that no environments are messed with
for _ = 1, 2 do dofile(modlib.mod.get_resource"test.lua") end
modlib.mod.include"obj.lua"
-- Texture module tests
dofile(modlib.mod.get_resource("modlib_test", "minetest", "texmod", "test.lua"))
-- Extensive PngSuite tests
dofile(modlib.mod.get_resource("modlib_test", "minetest", "png", "test.lua"))

modlib.mod.include"test_ingame.lua"
