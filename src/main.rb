APP_ROOT = File.dirname(__FILE__.gsub("file:", ""))+"/" #for finding the jar base path when running from jar
$:.push("src/")

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'streamroller'
require 'rackhacks'

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

m = StreamRoller::StreamRoller.new

r = Rack::Builder.new do
  map '/get' do
    run m
  end
  
  map '/pic' do
    run m
  end
  
  map '/' do
    use Rack::Deflater
    run m
  end
  
end

puts "Starting server; http://localhost:4567"
Rack::Handler::Mongrel.run r, :Port => 4567

