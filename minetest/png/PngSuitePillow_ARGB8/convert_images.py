#!/usr/bin/python3

from PIL import Image # requires Pillow
import io, os

def write_lua(in_path, out_path):
	file = io.open(out_path, "w")

	def write(text):
		file.write(text + "\n")

	write("return {")

	try:
		with Image.open(in_path) as im:
			im.verify()
			im = im.convert(mode="RGBA")
			write('\ttype="data";')
			write(f'\twidth={im.width:d};')
			write(f'\theight={im.height:d};')
			for y in range(im.height):
				for x in range(im.width):
					color = im.getpixel((x, y))
					write(f'\t0x{color[3]:02X}{color[0]:02X}{color[1]:02X}{color[2]:02X};')
	except BaseException as e:
		write('\ttype="error";')
		msg = str(e)
		if "]==" not in msg:
			write("\tmessage=[==[" + msg + "]==];")

	write("}")

	file.close()

for filename in os.listdir("../PngSuite"):
	if filename.endswith(".png"): 
		write_lua("../PngSuite/" + filename, filename + ".lua")

