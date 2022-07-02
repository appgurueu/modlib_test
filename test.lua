-- ensure modlib API isn't leaking into global environment
assert(modlib.bluon.assert ~= assert)

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
	__newindex = function(_, key, value)
		error(dump{key = key, value = value})
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
end

-- func
do
	local tab = {a = 1, b = 2}
	local function check_entry(key, value)
		assert(tab[key] == value)
		tab[key] = nil
	end
	func.iterate(check_entry, pairs(tab))
	assert(next(tab) == nil)

	tab = {a = 1, b = 2}
	local function pairs_callback(callback, tab)
		for k, v in pairs(tab) do
			callback(k, v)
		end
	end
	for k, v in func.for_generator(pairs_callback, tab) do
		check_entry(k, v)
	end
	assert(next(tab) == nil)
	assert(func.aggregate(func.add, 1, 2, 3) == 6)
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

-- string
assert(string.escape_magic_chars"%" == "%%")

-- table
do
	local tab = {}
	tab[tab] = tab
	local table_copy = table.deepcopy(tab)
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
				return -i
			end
		end
		return -#list-1
	end

	for k = 0, 100 do
		local sorted = {}
		for i = 1, k do
			sorted[i] = random(1, 1000)
		end
		_G.table.sort(sorted)
		for i = 1, 10 do
			local pick = random(-100, 1100)
			local linear, binary = linear_search(sorted, pick), table.binary_search(sorted, pick)
			-- If numbers appear twice (or more often), the indices may differ, as long as the number is the same.
			assert(linear == binary or (linear > 0 and sorted[linear] == sorted[binary]))
		end
	end
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

-- ranked set
do
	local n = 100
	local ranked_set = ranked_set.new()
	local list = {}
	for i = 1, n do
		ranked_set:insert(i)
		list[i] = i
	end

	assert(table.equals(ranked_set:to_table(), list))

	local i = 0
	for rank, key in ranked_set:ipairs() do
		i = i + 1
		assert(i == key and i == rank)
		assert(ranked_set:get_by_rank(rank) == key)
		local rank, key = ranked_set:get(i)
		assert(key == i and i == rank)
	end
	assert(i == n)

	for i = 1, n do
		local _, v = ranked_set:delete(i)
		assert(v == i, i)
	end
	assert(not next(ranked_set:to_table()))

	local ranked_set = ranked_set.new()
	for i = 1, n do
		ranked_set:insert(i)
	end

	for rank, key in ranked_set:ipairs(10, 20) do
		assert(rank == key and key >= 10 and key <= 20)
	end

	for i = n, 1, -1 do
		local j = ranked_set:delete_by_rank(i)
		assert(j == i)
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

-- Supports circular tables; does not support table keys
-- Correctly checks whether a mapping of references ("same") exists
-- Is significantly more efficient than assert.same
-- TODO consider moving this to modlib.table.equals_*
local function assert_same(a, b, same)
	same = same or {}
	if same[a] or same[b] then
		assert(same[a] == b and same[b] == a)
		return
	end
	if a == b then
		return
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		assert(a == b)
		return
	end
	same[a] = b
	same[b] = a
	local count = 0
	for k, v in pairs(a) do
		count = count + 1
		assert(type(k) ~= "table")
		assert_same(v, b[k], same)
	end
	for _ in pairs(b) do
		count = count - 1
	end
	assert(count == 0)
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
					expected_str = text.utf8(expected_str)
				end
				return assert(json:read_string('"' .. prefix .. str .. suffix .. '"') == prefix .. expected_str .. suffix)
			end
			test([[\uD834\uDD1E]], 0x1D11E)
			test([[\uDD1E\uD834]], text.utf8(0xDD1E) .. text.utf8(0xD834))
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
-- TODO modlib.binary testing (somewhat transitively tested through bluon)
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

assert(minetest.luon:read_string(minetest.luon:write_string(ItemStack"")))

-- colorspec
local colorspec = minetest.colorspec
local function test_from_string(string, number)
	local spec = colorspec.from_string(string)
	local expected = colorspec.from_number_rgba(number)
	assertdump(table.equals(spec, expected), {expected = expected, actual = spec})
end
local spec = colorspec.from_number_rgba(0xDDCCBBAA)
assertdump(table.equals(spec, {a = 0xAA, b = 0xBB, g = 0xCC, r = 0xDD}), spec)
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
	logfile:set_root({a = 1}, {b = 2, c = 3, d = _G.math.huge, e = -_G.math.huge, ["in"] = "keyword"})
	local circular = {}
	circular[circular] = circular
	logfile:set_root(circular, circular)
	logfile:close()
	logfile:init()
	assert(table.equals_references(logfile.root, {
		a_longer_string = "test",
		[{a = 1}] = {b = 2, c = 3, d = _G.math.huge, e = -_G.math.huge, ["in"] = "keyword"},
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
	local path = mod.get_resource("modlib", "database.test.sqlite3")
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
