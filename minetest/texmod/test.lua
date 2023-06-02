local texmod = modlib.minetest.texmod
local file = texmod.file
local a, b, c, d, e, f = file"a", file"b", file"c", file"d", file"e", file"f"
local tests = {
	-- "Blit"
	["a^b"] = a:blit(b),
	-- Associativity
	["a^b^c"] = a:blit(b):blit(c),
	-- Parentheses
	["(((a)))"] = a,
	["a^(b^c)"] = a:blit(b:blit(c)),
	["(a^b)^(c^d)"] = a:blit(b):blit(c:blit(d)),
	-- Base texture modifiers
	-- Param-less
	["a^[noalpha"] = a:noalpha(),
	["a^[brighten"] = a:brighten(),
	["a^[noalpha^[brighten"] = a:noalpha():brighten(),
	-- Simple parameterized ones
	["a^[makealpha:11,22,33"] = a:makealpha(11, 22, 33),
	["a^[opacity:42"] = a:opacity(42),
	["a^[invert:rgba"] = a:invert{
		r = true,
		g = true,
		b = true,
		a = true
	},
	["a^[verticalframe:42:10"] = a:verticalframe(42, 10),
	["a^[crack:1:2:3"] = a:crack(1, 2, 3),
	["a^[crack:1:2"] = a:crack(1, 2),
	["a^[cracko:1:2:3"] = a:cracko(1, 2, 3),
	["a^[cracko:1:2"] = a:cracko(1, 2),
	["a^[sheet:16x16:2,2"] = a:sheet(16, 16, 2, 2),
	["a^[resize:42x69"] = a:resize(42, 69),
	-- Transforms
	["a^[transformI"] = a,
	["a^[transform0"] = a,
	["a^[transformR90"] = a:rotate(90),
	["a^[transformR180"] = a:rotate(180),
	["a^[transformR270"] = a:rotate(270),
	["a^[transformR90R90R90"] = a:rotate(270),
	["a^[transformfx"] = a:transform"fx",
	["a^[transformFX"] = a:flip"x",
	["a^[transformFXfy"] = a:flip"x":flip"y",
	["a^[transform46"] = a:flip"y":flip"x",
	-- Colors
	["a^[multiply:red"] = a:multiply"red",
	["a^[colorize:red:alpha^[multiply:red^[resize:42x69"] = a:colorize("red", "alpha"):multiply"red":resize(42, 69),
	["a^[colorize:red:alpha"] = a:colorize("red", "alpha"),
	["blank.png^[noalpha^[colorize:#b8bab9"] = file"blank.png":noalpha():colorize"#b8bab9",
	["a^[colorizehsl:42:69:-10"] = a:colorizehsl(42, 69, -10),
	["a^[hsl:42:200:69"] = a:hsl(42, 200, 69),
	["a^[contrast:42:-42"] = a:contrast(42, -42),
	["a^[screen:blue"] = a:screen"blue",
	-- Modifiers which take textures as parameters
	["a^[mask:b"] = a:mask(b),
	["a^[hardlight:b"] = a:hardlight(b),
	["a^[overlay:b"] = a:overlay(b),
	["a^[mask:\\b"] = a:mask(b),
	[ [[a^[mask:b\^[mask\:c\\^[mask\\:d]] ] = a:mask(b:mask(c:mask(d))),
	-- unnecessary escaping
	["a^[lowpart:42:b"] = a:lowpart(42, b),
	["a^[lowpart:42:b^c"] = a:lowpart(42, b):blit(c),
	["a^[lowpart:42:b\\^c"] = a:lowpart(42, b:blit(c)),
	["a^[transformR90^[lowpart:50:b\\^[transformR90^[transformR270"] = a:rotate(90):lowpart(50, b:rotate(90)):rotate(270),
	-- Base-generating texture modifiers
	["[png:" .. minetest.encode_base64"test"] = texmod.png"test",
	["[inventorycube{a{b{c"] = texmod.inventorycube(a, b, c),
	["[inventorycube{a{b{c^d"] = texmod.inventorycube(a, b, c):blit(d),
	["[inventorycube{a{b{c&d"] = texmod.inventorycube(a, b, c:blit(d)),
	-- Overlaying a base-generating texture modifier
	["[inventorycube{a{b{c^[inventorycube{d{e{f"] = texmod.inventorycube(a, b, c):blit(texmod.inventorycube(d, e, f)),
	["[combine:42x69:"] = texmod.combine(42, 69, {}),
	["[combine:8x8:-8,-8=a"] = texmod.combine(8, 8, { { x = -8, y = -8, texture = a } }),
	["[combine:42x69:1,2=a:3,4=b"] = texmod.combine(42, 69, { { x = 1, y = 2, texture = a }, { x = 3, y = 4, texture = b } }),
	["[combine:42x69:1,2=a^b"] = texmod.combine(42, 69, { { x = 1, y = 2, texture = a } }):blit(b),
	["[combine:42x69:1,2=a\\^b"] = texmod.combine(42, 69, { { x = 1, y = 2, texture = a:blit(b) } }),
	["[combine:42x69:1,2=a\\^[multiply\\:red"] = texmod.combine(42, 69, {
		{ x = 1, y = 2, texture = a:multiply"red" }
	}),
	["[combine:42x69:1,2=[combine\\:33x99\\:3,4=a"] = texmod.combine(42, 69, {
		{
			x = 1,
			y = 2,
			texture = texmod.combine(33, 99, { { x = 3, y = 4, texture = a } })
		}
	}),
	["[combine:256x48:0,0=a:0,0=[combine\\:128x48\\:0,0=b"] = texmod.combine(256, 48, {
		{ x = 0, y = 0, texture = a },
		{
			x = 0,
			y = 0,
			texture = texmod.combine(128, 48, { { x = 0, y = 0, texture = b } })
		}
	}),
	["[fill:42x43:#AABBCCDD"] = texmod.fill(42, 43, "#AABBCCDD"),
	["a^[fill:42x43:10,11:green"] = a:fill(42, 43, 10, 11, "green"),
}
for str, tm in pairs(tests) do
	local parsed_tm = texmod.read_string(str)
	assert(modlib.table.equals_noncircular(tm, parsed_tm))
	assert(modlib.table.equals_noncircular(tm, texmod.read_string(tostring(tm))))
end
-- Test warning for `^` inside `(...)`
assert(not pcall(texmod.read_string, "a^[mask:(b^c)"))
assert(modlib.table.equals_noncircular(
	a:mask(b:blit(c)),
	texmod.read_string("a^[mask:(b^c)", function()end)))
do
	local test_file_dims = {
		["mine.png"] = {11, 22},
		["test.png"] = {44, 33},
	}
	local mine, test = file"mine.png", file"test.png"
	local function get_dim(filename)
		return unpack(assert(test_file_dims[filename]))
	end
	local function test_dims(w, h, tm)
		local got_w, got_h = tm:calc_dims(get_dim)
		assert(w == got_w and h == got_h)
	end
	test_dims(42, 69, texmod.combine(42, 69, {}))
	test_dims(44, 33, test:brighten():noalpha():screen"red")
	test_dims(42, 69, test:resize(42, 69))
	test_dims(42, 69, test:resize(42, 69))
	test_dims(44, 33, mine:blit(test))
	test_dims(44, 33, mine:overlay(test))
	test_dims(44, 33, mine:hardlight(test))
	test_dims(33, 44, test:rotate(90))
	test_dims(44, 11, test:verticalframe(3, 1))
	test_dims(math.floor(11 / 2), math.floor(22 / 2),
		mine:sheet(2, 2, 1, 1))
	test_dims(64, 64, texmod.inventorycube(mine, mine, test))
	test_dims(2, 3, texmod.png(modlib.file.read(modlib.mod.get_resource("modlib_test", "minetest", "texmod", "2x3.png"))))
	test_dims(42, 43, texmod.fill(42, 43, "red"))
	test_dims(11, 22, mine:fill(2, 3, 4, 5, "green"))
end
