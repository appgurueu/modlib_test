local tex = modlib.tex

assert(tex.new{
	w = 5, h = 1,
	1, 2, 3, 4, 5
}:rotated_90() == tex.new{
	w = 1, h = 5,
	1,
	2,
	3,
	4,
	5
})

assert(tex.new{
	w = 2, h = 2,
	1, 2,
	3, 4,
}:rotated_90() == tex.new{
	w = 2, h = 2,
	3, 1,
	4, 2,
})

assert(tex.new{
	w = 2, h = 3,
	1, 2,
	3, 4,
	5, 6,
}:rotated_90() == tex.new{
	w = 3, h = 2,
	5, 3, 1,
	6, 4, 2,
})

assert(tex.new{
	w = 3, h = 2,
	1, 2, 3,
	4, 5, 6,
}:rotated_90() == tex.new{
	w = 2, h = 3,
	4, 1,
	5, 2,
	6, 3,
})

do
	local t = tex.new{
		w = 3, h = 3,
		1, 2, 3,
		4, 5, 6,
		7, 8, 9,
	}
	t:crop(2, 2, 2, 2)
	assert(t == tex.new{w = 1, h = 1, 5})
end

local r, g, b = 0xFFFF0000, 0xFF00FF00, 0xFF0000FF
local t = tex.new{
	w = 2, h = 2,
	r, g,
	b, r
}
assert(t:resized(1, 1) == tex.new{w = 1, h = 1, 0xFF804040})
assert(t:resized(1, 2) == tex.new{w = 1, h = 2, 0xFF808000, 0xFF800080})
assert(t:resized(2, 1) == tex.new{w = 2, h = 1, 0xFF800080, 0xFF808000})
local c = 0x11223344
assert(tex.new{w=1,h=1,c}:resized(2, 2) == tex.new{w = 2, h = 2, c, c, c, c})
assert(tex.filled(16,80,0xFF000042):resized(16,16) == tex.filled(16,16,0xFF000042))
assert(tex.filled(16,16,0xFF000042):resized(16,80) == tex.filled(16,80,0xFF000042))
