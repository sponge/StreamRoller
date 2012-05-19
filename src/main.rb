$:.push("src/")

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'streamroller'
require 'rackhacks'
require 'java'

# Make jaudiotagger stfu

import 'java.util.logging.LogManager'
import 'java.io.StringBufferInputStream'

LogManager.getLogManager.read_configuration(java.io.StringBufferInputStream.new("org.jaudiotagger.level = SEVERE"))

additional_mime = {".flac" => "audio/x-flac"}
Rack::Mime::MIME_TYPES.merge!(additional_mime)

=begin
#JPG seems to be broken, force PNG for now
$imgformat = "jpg"
begin
  i = Magick::Image.new(1,1)
  i.format = "jpg"
  i.to_blob
rescue NativeException
  puts "Error: Unable to write jpeg image."
  puts "It is possible you are using OpenJDK, which does not support jpeg."
  puts "Falling back to PNG for images."
  $imgformat = "png"
end
=end
$imgformat = "png"

