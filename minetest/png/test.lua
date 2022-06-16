-- TODO test encoder
-- HACK this is somewhat hacky in its current form
local function quote_arg(arg)
	return table.concat(modlib.table.map(modlib.text.split(arg, "'"), function(p) return "'"..p.."'" end), [["'"]])
end
local path = modlib.mod.get_resource("modlib_test", "minetest", "png", "PngSuite")
-- Scripts to generate these tests reside in the respective folders
local pillow_path = path .. "Pillow_ARGB8"
local image_io_path = path .. "ImageIO_ARGB8"
-- Looks like Java "corrects" colors: https://stackoverflow.com/questions/29675337/java-bufferedimage-gray-to-rgb-conversion
-- https://github.com/conggao/jdkSourceStudy/blob/master/src/main/java/java/awt/image/ColorModel.java#L2098-L2119

-- Test errors
local expected_errs = {
	["xc1n0g08.png"]="invalid color type",
	["xc9n2c08.png"]="invalid color type",
	["xcrn0g04.png"]="CRC mismatch", -- CR
	["xcsn0g01.png"]="CRC mismatch",
	["xd0n2c08.png"]="disallowed bit depth",
	["xd3n2c08.png"]="disallowed bit depth",
	["xd9n2c08.png"]="disallowed bit depth",
	["xdtn0g01.png"]="no IDAT chunk",
	["xhdn0g08.png"]="CRC mismatch",
	["xlfn0g04.png"]="CRC mismatch", -- LF
	["xs1n0g01.png"]="PNG signature expected",
	["xs2n0g01.png"]="PNG signature expected",
	["xs4n0g01.png"]="PNG signature expected",
	["xs7n0g01.png"]="PNG signature expected"
}
for filename, errmsg in pairs(expected_errs) do
	local file = io.open(path .. "/" .. filename, "r")
	local status, error = pcall(modlib.minetest.decode_png, file)
	file:close()
	assert(not status, error:find(errmsg))
	if errmsg ~= "CRC mismatch" then
		assert(dofile(pillow_path .. "/" .. filename .. ".lua").type == "error", filename)
	end
end

local files = {}

for _, filename in pairs(minetest.get_dir_list(path, false)) do
	if modlib.text.ends_with(filename, ".png") and not expected_errs[filename] then
		local file = io.open(path .. "/" .. filename, "r")
		local png = modlib.minetest.decode_png(file)
		file:close()
		modlib.minetest.convert_png_to_argb8(png)

		local expected_data = {
			pillow = dofile(pillow_path .. "/" .. filename .. ".lua"),
			imageio = dofile(image_io_path .. "/" .. filename .. ".lua")
		}
		
		files[filename] = {equals_pillow = true, equals_imageio = true}

		if not modlib.table.equals_noncircular(expected_data.pillow, expected_data.imageio) then
			files[filename].pillow_equals_imageio = false
		end

		assert(expected_data.pillow.type == "data")
		assert(png.width == expected_data.pillow.width and png.height == expected_data.pillow.height and #png.data == #expected_data.pillow)

		for index, color in ipairs(png.data) do
			if expected_data.pillow[index] ~= color then
				files[filename].equals_pillow = false
				break
			end
		end
		for index, color in ipairs(png.data) do
			if expected_data.imageio[index] ~= color then
				files[filename].equals_imageio = false
				break
			end
		end

		local basename = filename:sub(1, -5)
		if not (files[filename].equals_pillow and files[filename].equals_imageio) then
			for suffix, data in pairs{
				[""] = png.data,
				["_expected_iio"] = expected_data.imageio,
				["_expected_pillow"] = expected_data.pillow
			} do
				modlib.file.write(path .. "Comparison_ARGB8/" .. basename .. suffix .. ".png", modlib.minetest.encode_png(png.width, png.height, data, 9))
			end
		end
	end
end

-- Regression test
assert(modlib.table.equals_noncircular(files, {
	["g05n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s08n3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s04i3p01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["tbgn3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s06n3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s07n3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g04n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["cs8n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g25n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["tbgn2c16.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g10n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s40n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s35n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["cs3n2c16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["s38n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s33n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["oi4n2c16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["s40i3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["ps1n2c16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["z00n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s38i3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s33i3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s32i3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["oi2n2c16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["z03n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["oi1n2c16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["ctjn0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g25n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["oi9n0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["oi4n0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["ctfn0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["f04n0g08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["cten0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["f04n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g05n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["f03n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["oi1n0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["tm3n3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["oi2n0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["g10n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["f03n0g08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["f99n0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["ch1n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["z09n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basi0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["ch2n3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn0g08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["basi0g08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["tbrn2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["cdun2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn6a08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["ccwn2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["bgan6a08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basi6a08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["exif2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["cdsn2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basi3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g07n0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["g04n0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["g25n0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["basi2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["cs8n3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["bgbn4a08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["cs3n3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["tbbn0g04.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["g03n0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["basi3p01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basi3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn3p01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["tp0n3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["ps1n0g08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["tp1n3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["tp0n0g08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["ps2n0g08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["basn3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["pp0n6a08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["cdfn2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s39i3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["PngSuite.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s01n3p01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["ct1n0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["cdhn2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["bgai4a08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["basn2c16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["tbwn0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["f01n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s34n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s37n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["bgwn6a08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["f01n0g08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["ct0n0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["ctzn0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn4a08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["cs5n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g07n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s04n3p01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["cs5n3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["bgyn6a16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["tbbn3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s09n3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s34i3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s36i3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s02n3p01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s36n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["ps2n2c16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["cthn0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn0g01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["f02n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn6a16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["s09i3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s05n3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basi0g01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["bgan6a16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["basi0g02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basi4a08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["tp0n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["f00n0g08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["cm9n0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g03n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["tbbn2c16.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g04n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s03n3p01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["z06n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["tbwn3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s39n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["cm0n0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g03n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["pp0n2c16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["basn0g02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g05n0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["basn4a16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["f02n0g08.png"] = {
		equals_pillow = true,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["oi9n2c16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = true
	},
	["basi3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s35i3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["cm7n0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["ccwn3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s32n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["f00n2c08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["basn3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s37i3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g10n0g16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["s08i3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["tbyn3p08.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["ctgn0g04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s02i3p01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s06i3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s01i3p01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s07i3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["g07n3p04.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["bggn4a16.png"] = {
		equals_pillow = false,
		pillow_equals_imageio = false,
		equals_imageio = false
	},
	["s03i3p01.png"] = {
		equals_imageio = true,
		equals_pillow = true
	},
	["s05i3p02.png"] = {
		equals_imageio = true,
		equals_pillow = true
	}
}))
