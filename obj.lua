local comments = [[
# A simple 2³ cube centered at the origin; each face receives a separate texture / tile
# no care was taken to ensure "proper" texture orientation
]]

local cube_obj = [[
v -1 -1 -1
v -1 -1 1
v -1 1 -1
v -1 1 1
v 1 -1 -1
v 1 -1 1
v 1 1 -1
v 1 1 1
vn -1 0 0
vn 0 -1 0
vn 0 0 -1
vn 1 0 0
vn 0 1 0
vn 0 0 1
vt 0 0
vt 1 0
vt 0 1
vt 1 1
g negative_x
f 1/1/1 3/3/1 2/2/1 4/4/1
g negative_y
f 1/1/2 5/3/2 2/2/2 6/4/2
g negative_z
f 1/1/3 5/3/3 3/2/3 7/4/3
g positive_x
f 5/1/4 7/3/4 2/2/4 8/4/4
g positive_y
f 3/1/5 7/3/5 4/2/5 8/4/5
g positive_z
f 2/1/6 6/3/6 4/2/6 8/4/6
]]

assert(modlib.minetest.obj.read_string(comments .. cube_obj):write_string() == cube_obj)
