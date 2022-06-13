-- Run all tests twice to ensure that no environments are messed with
for _ = 1, 2 do dofile(modlib.mod.get_resource"test.lua") end
-- Extensive PngSuite tests
dofile(modlib.mod.get_resource("modlib_test", "minetest", "png", "test.lua"))
