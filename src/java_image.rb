require 'java'

module StreamRoller
  class JavaImage

    def initialize(original)
      @original = original
    end

    def self.load(path)
      f = java.io.File.new(path)
      buffered_image = javax.imageio.ImageIO.read(f)
      new(buffered_image)
    end

    def resize(length, width)
      resized = java.awt.image.BufferedImage.new(length, width, @original.type)
      graphics = resized.create_graphics
      graphics.draw_image(@original, 0, 0, length, width, nil)
      graphics.dispose
      JavaImage.new(resized)
    end

    def to_blob
      ba = java.io.ByteArrayOutputStream.new
      format = $imgformat || "jpg"
      javax.imageio.ImageIO.write(@original, format, ba)
      String.from_java_bytes(ba.to_byte_array)
    end
  end
end