-- ensure modlib API isn't leaking into global environment
assert(modlib.bluon.assert == nil)

local random, huge = math.random, math.huge
local parent_env = getfenv(1)
setfenv(1, setmetatable({}, {
	__index = function(_, key)
		local value = modlib[key]
		if value ~= nil then
			return value
		end
		return parent_env[key]
	end,
	__newindex = function()
		error("attempt to index test environment")
	end
}))

-- math
do
	local function assert_tonumber(num, base)
		local str = math.tostring(num, base)
		assert(tonumber(str, base) == num, str)
	end
	assert_tonumber(134217503, 36)
	assert_tonumber(3.14, 10)
	for i = -100, 100 do
		local log = math.log[2](2^i)
		assert(_G.math.abs(log - i) < 2^-40) -- Small tolerance for floating-point precision errors
		assert(math.log(2^i) == _G.math.log(2^i))
		assert(math.log(2^i, 2) == log)
	end
	-- fround
	assert(math.fround(0.999999999999996114) == 1)
	for _ = 1, 1e3 do
		local rnd_num = (_G.math.random() - 0.5) * 2^math.random(-100, 100)
		assert(_G.math.abs(math.fround(rnd_num) - rnd_num) / rnd_num < 2^-22)
	end
	-- random tests
	local n = 1e6
	local function test_avg(min, max, int, ...)
		local sum = 0
		local func = math[int and "randint" or "random"]
		for _ = 1, n do
			local r = func(...)
			assert(r >= min)
			if int then
				assert(r <= max)
			else
				assert(r < max)
			end
			sum = sum + r
		end
		assert((sum/n - (min + max)/2) / (max - min) < 1e-3)
	end
	test_avg(0, 1, false)
	test_avg(0, 42, false, 42)
	test_avg(1e3, 1e6, false, 1e3, 1e6)
	test_avg(0, 2^53 - 1, true)
	test_avg(0, 42, true, 42)
	test_avg(1e3, 1e6, true, 1e3, 1e6)
end

-- func
do
	local called = false
	local function fun(arg)
		assert(arg == "test")
		local retval = called
		called = true
		return retval
	end
	local memo = func.memoize(fun)
	assert(memo"test" == false)
	assert(memo.test == false)
end

-- less than utils
do
	local t = {{field = 1}, {field = 2}, {field = 3}}
	_G.table.sort(t, less_than.gt(less_than.by_field"field"))
	assert(table.equals(t, {{field = 3}, {field = 2}, {field = 1}}))
end

-- iterator
do
	local function assert_equals_list(list, ...)
		assert(table.equals(list, iterator.to_list(...)))
	end
	local function assert_equals_table(list, ...)
		assert(table.equals(list, iterator.to_table(...)))
	end
	local range = iterator.range
	assert(not iterator.empty(range(1, 3)))
	assert(iterator.first(range(2, 3)) == 2)
	assert(iterator.last(range(1, 10)) == 10)
	assert(iterator.aggregate(func.add, 0, range(1, 3)) == 6)
	assert(iterator.select(42, range(1, 100)) == 42)
	local closure = iterator.wrap(range(1, 100))
	assert(closure() == 1 and closure() == 2)
	assert(iterator.last(closure) == 100)
	assert_equals_list({2, 4, 6, 8, 10}, iterator.filter(
		function(x) return x % 2 == 0 end,
		range(1, 10)))
	assert_equals_list({true, 1, "yay"}, iterator.truthy(table.ivalues{false, true, 1, "yay", false}))
	assert_equals_list({false, false}, iterator.falsy(table.ivalues{false, true, 1, false}))
	assert_equals_list({"\1\11", "\2\22", "\3\33"}, iterator.map(
			_G.string.char,
			ipairs{11, 22, 33}))
	assert_equals_table({a = 1 * 42, b = 2 * 42, c = 3 * 42}, iterator.map_values(
		function(x) return x * 42 end,
		pairs{a = 1, b = 2, c = 3}))
	assert_equals_list({1, 2, 3, 1, 2, 3, 1, 2, 3}, iterator.rep(3, range(1, 3)))
	assert_equals_table({42, 33}, iterator.limit(2, ipairs{42, 33, 101}))
	assert(iterator.reduce(func.add, range(1, 3)) == 6)
	assert(select("#", iterator.reduce(func.add, function()end)) == 0)
	assert(iterator.sum(range(1, 3)) == 6)
	assert(iterator.min(func.lt, range(1, 3)) == 1)
	assert(iterator.count(range(1, 3)) == 3)
	assert(iterator.average(range(1, 3)) == 2)
	assert(iterator.standard_deviation(range(1, 3)) == (2/3)^.5)

	local tab = {a = 1, b = 2}
	local function check_entry(key, value)
		assert(tab[key] == value)
		tab[key] = nil
	end
	iterator.foreach(check_entry, pairs(tab))
	assert(next(tab) == nil)

	tab = {a = 1, b = 2}
	local function pairs_callback(callback, tab)
		for k, v in pairs(tab) do
			callback(k, v)
		end
	end
	for k, v in iterator.for_generator(pairs_callback, tab) do
		check_entry(k, v)
	end
	assert(next(tab) == nil)
end

-- text
assert(text.escape_magic_chars"%" == "%%")
assert(text.starts_with("abc", "a") == true)
assert(text.starts_with("abc", "b") == false)
assert(text.ends_with("abc", "c") == true)
assert(text.ends_with("abc", "b") == false)
assert(text.contains("abc", "b") == true)
assert(text.contains("abc", "d") == false)
assert(text.contains("abc", "a.c", false) == true) -- with pattern
assert(text.trim_spacing("\t some text\n") == "some text")
assert(table.equals(iterator.to_list(text.spliterator(" space   delimited \t\n stuff", "%s+")),
	{"", "space", "delimited", "stuff"}))
assert(table.equals(iterator.to_list(text.spliterator(".dot.delimited.stuff.with.trailing.empty.", ".", true)),
	{"", "dot", "delimited", "stuff", "with", "trailing", "empty", ""}))
assert(table.equals(iterator.to_table(text.ichars("helloworld", #"hello" + 1)),
	{[6] = "w", [7] = "o", [8] = "r", [9] = "l", [10] = "d"}))
assert(table.equals(iterator.to_table(text.ibytes("hello")),
	table.map({"h", "e", "l", "l", "o"}, _G.string.byte)))
assert(table.equals(iterator.to_list(text.lines("\r\n2\n\n4\r5\r\n")),
	{"", "2", "", "4", "5"}))

-- utf8
for codepoint = 0, 0x10FFFF do
	assert(utf8.codepoint(utf8.char(codepoint)) == codepoint)
end
for _ = 1, 10 do
	local codepoints = {}
	for i = 1, random(100) do
		codepoints[i] = random(0x10FFFF)
	end
	local i = 0
	for _, codepoint in utf8.codes(utf8.char(unpack(codepoints))) do
		i = i + 1
		assert(codepoints[i] == codepoint)
	end
	assert(#codepoints == i)
end

-- table
do
	local tab = {}
	tab[tab] = tab
	setmetatable(tab, tab)
	local table_copy = table.deepcopy(tab)
	assert(getmetatable(table_copy) == getmetatable(tab))
	assert(table_copy[table_copy] == table_copy)
	assert(table.is_circular(tab))
	assert(not table.is_circular{a = 1})
	assert(table.equals_noncircular({[{}]={}}, {[{}]={}}))
	assert(table.equals_content(tab, table_copy))
	local equals_references = table.equals_references
	assert(equals_references(tab, table_copy))
	assert(equals_references({}, {}))
	assert(not equals_references({a = 1, b = 2}, {a = 1, b = 3}))
	tab = {}
	tab.a, tab.b = tab, tab
	table_copy = table.deepcopy(tab)
	assert(equals_references(tab, table_copy))
	local x, y = {}, {}
	assert(not equals_references({[x] = x, [y] = y}, {[x] = y, [y] = x}))
	assert(equals_references({[x] = x, [y] = y}, {[x] = x, [y] = y}))
	local nilget = table.nilget
	assert(nilget({a = {b = {c = 42}}}, "a", "b", "c") == 42)
	assert(nilget({a = {}}, "a", "b", "c") == nil)
	assert(nilget(nil, "a", "b", "c") == nil)
	assert(nilget(nil, "a", nil, "c") == nil)
	assert(table.min_key(table.set{-3, 1, 2, -42}) == -42)
	assert(table.min_value{-3, 1, 2, -42} == -42)
	assert(table.equals(table.slice({1, 2, 3, 4, 5},
		2, -- start index
		4 -- end index
	), {2, 3, 4}))
	do
		assert(table.equals(table.splice({1, 42, 5},
			2, -- start index
			1, -- delete count
			2, 3, 4 -- elements to add
		), {1, 2, 3, 4, 5}))
		assert(table.equals(table.splice(
			{1, 42, 42, 3, 4, 5},
			2, -- start index
			2, -- delete count
			2 -- element to add
		), {1, 2, 3, 4, 5}))
		assert(table.equals(table.splice(
			{1, 2, 3, 4, 5},
			2, -- start index
			3 -- delete count
		), {1, 5}))
	end
	do
		local t = {1, 2, 3}
		table.move(t, 1, 4, 3)
		assert(table.equals(t, {1, 2, 3, 1, 2, 3}))
		table.move(t, 6, 3, 3)
		assert(table.equals(t, {1, 2, 3}))
		local c = {}
		table.move(t, 1, 1, #t, c)
		assert(table.equals(t, c))
	end
	do
		local deepset = table.deepset
		local t = {}
		deepset(t, "a", 1)
		deepset(t, "b", "c", "d", 2)
		deepset(t, "b", "c", "e", 3)
		assert(table.equals_noncircular(t, {a = 1, b = {c = {d = 2, e = 3}}}))
	end
	do
		assert(table.count_equals({}, 0))
		assert(table.count_equals({1}, 1))
		assert(table.count_equals({[false] = 1, [true] = 2}, 2))
		assert(table.count_equals({1, 2, 3}, 3))
		assert(not table.count_equals({a = 1, b = 2}, 0))
		assert(not table.count_equals({}, 1))
		assert(not table.count_equals({1, 2, 3, 4, 5}, 3))
		assert(not table.count_equals({1, 2, 3, 4, 5}, 6))
	end
	do
		local t = {
			"some", "list", "items";
			[huge] = 1, [-huge] = 2,
			[false] = 3, [true] = 4,
			str = 5, str_2 = 6,
			[0] = 7, [0.999999] = 8,
			-- can't test [len + x] = y since that would make len + x a valid len
		}
		for k, v in table.hpairs(t) do
			assert(t[k] == v)
			t[k] = nil
		end
		assert(table.equals_noncircular(t, {"some", "list", "items"}))
	end
	do
		assert(modlib.table.equals_noncircular(modlib.table.merge({
			a = {1, 2},
			b = 2,
		}, {
			a = {nil, nil, 3, 4},
			c = 3
		}), {
			a = {1, 2, 3, 4},
			b = 2,
			c = 3
		}))
	end
	local rope = table.rope{}
	rope:write"hello"
	rope:write" "
	rope:write"world"
	assert(rope:to_text() == "hello world", rope:to_text())
	tab = {a = 1, b = {2}}
	tab[3] = tab
	local contents = {
		a = 1,
		[1] = 1,
		b = 1,
		[tab.b] = 1,
		[2] = 1,
		[tab] = 1,
		[3] = 1
	}
	table.deep_foreach_any(tab, function(content)
		assert(contents[content], content)
		contents[content] = 2
	end)
	for _, value in pairs(contents) do
		assert(value == 2)
	end

	-- Test table.binary_search against a linear search
	local function linear_search(list, value)
		for i, val in ipairs(list) do
			if val == value then
				return i
			end
			if val > value then
				return nil, i
			end
		end
		return nil, #list
	end

	for k = 0, 100 do
		local sorted = {}
		for i = 1, k do
			sorted[i] = random(1, 1000)
		end
		_G.table.sort(sorted)
		for _ = 1, 10 do
			local pick = random(-100, 1100)
			local i, insertion_i = linear_search(sorted, pick)
			local j, insertion_j = table.binary_search(sorted, pick)
			-- If numbers appear twice (or more often), the indices may differ, as long as the number is the same.
			assert(i == j or (i and sorted[i] == sorted[j]) and (insertion_i == insertion_j))
		end
	end
end

-- vararg
do
	local pack = vararg.pack

	assert(vararg.aggregate(func.add, 0, 1, 2, 3) == 6)
	assert(pack(1, 2, 3):aggregate(func.add, 0) == 6)

	local va = pack(1, nil, 2)
	local a, b, c = va:unpack()
	assert(a == 1 and b == nil and c == 2)
	assert(va:select(2) == nil)
	assert(select("#", va:select(4)) == 0)
	local n = 0
	for i, v in va:ipairs() do assert(va:select(i) == v); n = n + 1 end
	assert(n == 3)
	assert(va:equals(pack(1, nil, 2)))
	assert(not va:equals(pack(1)))
	assert(pack(1) ~= pack(2))
	assert(va:concat(pack(3, nil, 4)) == pack(1, nil, 2, 3, nil, 4))
	assert(va .. pack(3, nil, 4) == pack(1, nil, 2, 3, nil, 4))
end

-- heaps
do
	local n = 100
	for _, heap in pairs{heap, hashheap} do
		local list = {}
		for index = 1, n do
			list[index] = index
		end
		table.shuffle(list)
		local heap = heap.new()
		for index = 1, #list do
			heap:push(list[index])
		end
		for index = 1, #list do
			local popped = heap:pop()
			assert(popped == index)
		end
	end
	do -- just hashheap
		local heap = hashheap.new()
		for i = 1, n do
			heap:push(i)
		end
		heap:replace(42, 0)
		assert(heap:pop() == 0)
		heap:replace(69, 101)
		assert(not heap:find_index(69))
		assert(heap:find_index(101))
		heap:remove(101)
		assert(not heap:find_index(101))
		heap:push(101)
		local last = 0
		for _ = 1, 98 do
			local new = heap:pop()
			assert(new > last)
			last = new
		end
		assert(heap:pop() == 101)
	end
end

-- hashlist
do
	local n = 100
	local list = hashlist.new{}
	for i = 1, n do
		list:push_tail(i)
	end
	for i = 1, n do
		local head = list:get_head()
		assert(head == list:pop_head(i) and head == i)
	end
end

-- k-d-tree
local vectors = {}
for _ = 1, 1000 do
	_G.table.insert(vectors, {random(), random(), random()})
end
local kdtree = kdtree.new(vectors)
for _, v in ipairs(vectors) do
	local neighbor, distance = kdtree:get_nearest_neighbor(v)
	assert(vector.equals(v, neighbor), distance == 0)
end

for _ = 1, 1000 do
	local v = {random(), random(), random()}
	local _, distance = kdtree:get_nearest_neighbor(v)
	local min_distance = huge
	for _, w in ipairs(vectors) do
		local other_distance = vector.distance(v, w)
		if other_distance < min_distance then
			min_distance = other_distance
		end
	end
	assert(distance == min_distance)
end

-- vector
assert(vector.new{1, 2, 3}:reflect{0, 1, 0} == vector.new{1, -2, 3})
assert(vector.new{1, 0, 0}:reflect(vector.normalize{1, 1, 0}):multiply_scalar(1e6):apply(math.round) == vector.new{0, -1e6, 0})

local function assert_same(a, b)
	return modlib.table.same(a, b)
end

local function serializer_test(is_json, preserve)
	local function assert_preserves(value)
		assert_same(value, preserve(value))
	end

	local atomics = is_json and {true, false} or {true, false, huge, -huge} -- no NaN or nil
	-- TODO proper deep table comparison with nan support
	for _, atomic in pairs(atomics) do
		assert_preserves(atomic)
	end
	local function atomic()
		return atomics[random(1, #atomics)]
	end
	if not is_json then
		local nan = preserve(0/0)
		assert(nan ~= nan)
	end
	-- Strings
	local function charcodes(count)
		if count == 0 then return end
		return random(0, 0xFF), charcodes(count - 1)
	end
	local function str()
		return _G.string.char(charcodes(random(0, 100)))
	end
	for _ = 1, 1e3 do
		assert_preserves(str())
	end
	-- Numbers
	for _, num in pairs{
		0,
		1e6,
		1.8997128170018022e+41,
		-2.8930711260329e+26,
		1.315802651898e+24,
		2.9145637014948988508e-06,
		1.1496387980481e-07,
	} do
		assert_preserves(num)
	end
	local function int()
		return random(-2^29, 2^29)
	end
	local function num()
		if random() < 0.5 then return int() end
		return int() * 2^random(-150, 150)
	end
	for _ = 1, 1e3 do
		assert_preserves(num())
	end
	-- Simple tables
	assert_preserves{hello = "world", welt = "hallo"}
	assert_preserves{a = 1, b = "hallo", c = "true"}
	assert_preserves{"hello", "hello", "hello"}
	assert_preserves{1, 2, 3, true, false}

	if is_json then return end -- The following circular / mixed / keyword tables are irrelevant to JSON testing

	-- TODO test JSON serialization with fuzzed lists & dicts (but no mixed tables)
	do -- fuzzing
		local primitives = {atomic, num, str}
		local function primitive()
			return primitives[random(1, #primitives)]()
		end
		local function tab(max_actions)
			local root = {}
			local tables = {root}
			local function random_table()
				return tables[random(1, #tables)]
			end
			for _ = 1, random(1, max_actions) do
				local tab = random_table()
				local value
				if random() < 0.5 then
					if random() < 0.5 then
						value = random_table()
					else
						value = {}
						tables[#tables + 1] = value
					end
				else
					value = primitive()
				end
				tab[random() < 0.5 and (#tab + 1) or primitive()] = value
			end
			return root
		end
		for _ = 1, 100 do
			local fuzzed_table = tab(1e3)
			assert_same(fuzzed_table, table.copy(fuzzed_table))
			assert_preserves(fuzzed_table)
		end
	end

	function assert_preserves(table)
		-- Some of the below tables use table keys, which the simple assert_same doesn't support
		assert(modlib.table.equals_references(table, preserve(table)))
	end

	local circular = {}
	circular[circular] = circular
	circular[1] = circular
	assert_preserves(circular)
	local mixed = {1, 2, 3}
	mixed[mixed] = mixed
	mixed.vec = {x = 1, y = 2, z = 3}
	mixed.vec2 = table.copy(mixed.vec)
	mixed.blah = "blah"
	assert_preserves(mixed)
	local a, b, c = {}, {}, {}
	a[a] = a; a[b] = b; a[c] = c;
	b[a] = a; b[b] = b; b[c] = c;
	c[a] = a; c[b] = b; c[c] = c;
	a.a = {"a", a = a}
	assert_preserves(a)
	assert_preserves{["for"] = "keyword", ["in"] = "keyword"}
end

-- JSON
do
	serializer_test(true, function(object)
		return json:read_string(json:write_string(object))
	end)
	-- Verify spacing is accepted
	assert(table.equals_noncircular(json:read_string'\t\t\n{ "a"   : 1, \t"b":2, "c" : [ 1, 2 ,3  ]   }  \n\r\t', {a = 1, b = 2, c = {1, 2, 3}}))
	-- Simple surrogate pair tests
	for _, prefix in pairs{"x", ""} do
		for _, suffix in pairs{"x", ""} do
			local function test(str, expected_str)
				if type(expected_str) == "number" then
					expected_str = utf8.char(expected_str)
				end
				return assert(json:read_string('"' .. prefix .. str .. suffix .. '"') == prefix .. expected_str .. suffix)
			end
			test([[\uD834\uDD1E]], 0x1D11E)
			test([[\uDD1E\uD834]], utf8.char(0xDD1E) .. utf8.char(0xD834))
			test([[\uD834]], 0xD834)
			test([[\uDD1E]], 0xDD1E)
		end
	end
end

-- luon
do
	serializer_test(false, function(object)
		return luon:read_string(luon:write_string(object))
	end)
end

-- bluon
do
	serializer_test(false, function(object)
		local rope = table.rope{}
		local written, read, input
		bluon:write(object, rope)
		written = rope:to_text()
		input = text.inputstream(written)
		read = bluon:read(input)
		local remaining = input:read(1)
		assert(not remaining)
		return read
	end)
end

do -- binary tests: float reading & writing
	local function write_string(func, num)
		local bytes = {}
		func(function(byte) bytes[#bytes + 1] = byte end, num)
		return _G.string.char(unpack(bytes))
	end
	local function read_string(func, str)
		local i = 0
		return func(function() i = i + 1; return str:byte(i) end)
	end
	local function preserve_func(funcname)
		local write, read = binary["write_" .. funcname], binary["read_" .. funcname]
		return function(num)
			return read_string(read, write_string(write, num))
		end
	end
	local preserve_single, preserve_double = preserve_func"single", preserve_func"double"
	for _, preserve in pairs{preserve_single, preserve_double} do
		assert(preserve(0) == 0)
		assert(preserve(1e9) == 1e9)
		assert(preserve(huge) == huge)
		assert(preserve(-huge) == -huge)
		local nan = preserve(0/0)
		assert(nan ~= nan)
		-- Test 32-bit floats
		for _ = 1, 1e3 do
			local int = random(-2^23, 2^23)
			assert(preserve(int) == int)
			local float = int * 2^random(-100, 100)
			assert(preserve(float) == float)
		end
		-- Test subnormal numbers
		for _ = 1, 1e3 do
			local subnormal = random(-2^8, 2^8) * 2^random(-137, -127)
			assert(preserve(subnormal) == subnormal)
		end
	end
	-- Test 64-bit doubles
	for _ = 1, 1e3 do
		local int = (random() < 0.5 and -1 or 1) * random(0, 2^26) * 2^26 + random(0, 2^26 - 1)
		assert(preserve_double(int) == int)
		local float = int * 2^random(-1000, 1000)
		assert(preserve_double(float) == float)
	end
	-- TODO test against other implementations (binarystream etc.)
end

do
	local text = "<tag> & '\""
	local escaped = web.html.escape(text)
	assert(web.html.unescape(escaped) == text)
	assert(web.html.unescape"&#42;" == _G.string.char(42))
	assert(web.html.unescape"&#x42;" == _G.string.char(0x42))
	assert(web.uri.encode"https://example.com/foo bar" == "https://example.com/foo%20bar")
	assert(web.uri.encode_component"foo/bar baz" == "foo%2Fbar%20baz")
end

if not _G.minetest then return end

local stack = ItemStack"default:dirt 42"
assert(minetest.luon:read_string(minetest.luon:write_string(stack)):to_string() == stack:to_string())

-- colorspec
local colorspec = minetest.colorspec
local function test_from_string(string, number)
	local spec = colorspec.from_string(string)
	local expected = colorspec.from_number_rgba(number)
	assert(table.equals(spec, expected))
end
local spec = colorspec.from_number_rgba(0xDDCCBBAA)
assert(table.equals(spec, {a = 0xAA, b = 0xBB, g = 0xCC, r = 0xDD}))
test_from_string("aliceblue", 0xf0f8ffff)
test_from_string("aliceblue#42", 0xf0f8ff42)
test_from_string("aliceblue#3", 0xf0f8ff33)
test_from_string("#333", 0x333333FF)
test_from_string("#694269", 0x694269FF)
test_from_string("#11223344", 0x11223344)
assert(colorspec.from_string"#694269":to_string() == "#694269")

-- Persistence
local function test_logfile(reference_strings)
	local path = mod.get_resource"logfile.test.lua"
	os.remove(path)
	local logfile = persistence.lua_log_file.new(path, {root_preserved = true}, reference_strings)
	logfile:init()
	assert(logfile.root.root_preserved)
	logfile.root = {a_longer_string = "test"}
	logfile:rewrite()
	logfile:set_root({a = 1}, {b = 2, c = 3, d = huge, e = -huge, ["in"] = "keyword"})
	local circular = {}
	circular[circular] = circular
	logfile:set_root(circular, circular)
	logfile:close()
	logfile:init()
	assert(table.equals_references(logfile.root, {
		a_longer_string = "test",
		[{a = 1}] = {b = 2, c = 3, d = huge, e = -huge, ["in"] = "keyword"},
		[circular] = circular,
	}))
	if not reference_strings then
		for key in pairs(logfile.references) do
			assert(type(key) ~= "string")
		end
	end
	os.remove(path)
end
test_logfile(true)
test_logfile(false)
-- SQLite3
do
	local sqlite3 = persistence.sqlite3()
	local path = mod.get_resource"database.test.sqlite3"
	local p = sqlite3.new(path, {})
	p:init()
	p:rewrite()
	p:set_root("key", "value")
	assert(p.root.key == "value")
	p:set_root("other key", "other value")
	p:set_root("key", "other value")
	p:set_root("key", nil)
	local x = { x = 1, y = 2 }
	p:set_root("x1", x)
	p:set_root("x2", x)
	p:set_root("x2", nil)
	p:set_root("x1", nil)
	p:set_root("key", { a = 1, b = 2, c = { a = 1 } })
	p:set_root("key", nil)
	p:set_root("key", { a = 1, b = 2, c = 3 })
	local cyclic = {}
	cyclic.cycle = cyclic
	p:set_root("cyclic", cyclic)
	p:set_root("cyclic", nil)
	p:collectgarbage()
	p:defragment_ids()
	local rows = {}
	for row in p.database:rows("SELECT * FROM table_entries ORDER BY table_id, key_type, key") do
		_G.table.insert(rows, row)
	end
	assert(table.equals(rows, {
		{ 1, 3, "key", 4, 2 },
		{ 1, 3, "other key", 3, "other value" },
		{ 2, 3, "a", 2, 1 },
		{ 2, 3, "b", 2, 2 },
		{ 2, 3, "c", 2, 3 },
	}))
	p:close()
	p = sqlite3.new(path, {})
	p:init()
	assert(table.equals(p.root, {
		key = { a = 1, b = 2, c = 3 },
		["other key"] = "other value",
	}))
	p:close()
	os.remove(path)
end
