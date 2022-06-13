import java.awt.image.BufferedImage;
import java.io.*;
import javax.imageio.*;

class ImageReader {
	public static void main(String[] args) throws IOException {
		for (File f : new File("../PngSuite").listFiles()) {
			BufferedWriter bw = new BufferedWriter(new FileWriter(new File(f.getName() + ".lua")));
			bw.write("return {\n");
			try {
				BufferedImage img = ImageIO.read(f);
				bw.write("\ttype=\"data\";\n");
				bw.write("\twidth=" + img.getWidth() + ";\n");
				bw.write("\theight=" + img.getHeight() + ";\n");
				for (int y = 0; y < img.getHeight(); y++) {
					for (int x = 0; x < img.getWidth(); x++) {
						int color = img.getRGB(x, y);
						int alpha = color >>> 24;
						int red = (color & 0x00FF0000) >> 16;
						int green = (color & 0x0000FF00) >> 8;
						int blue = color & 0x000000FF;
						bw.write(String.format("\t0x%02X%02X%02X%02X;\n", alpha, red, green, blue));
					}
				}
			} catch (Exception e) {
				bw.write("\ttype=\"error\";\n");
				if (!e.toString().contains("]=="))
					bw.write("\tmessage=[==[" + e.toString() +  "]==];\n");
			}
			bw.write("}");
			bw.close();
		}
	}
}