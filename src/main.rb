APP_ROOT = File.dirname(__FILE__.gsub("file:", ""))+"/" #for finding the jar base path when running from jar
$:.push(APP_ROOT)

$exec_from_jar ||= false #initalized from Main.java as true, if being invoked via jar-file

if not $exec_from_jar
  $:.push("lib/ruby/") #for the frozen gems and other deps when running in development mode
  $:.push("lib/java/")
end

require 'rack'
require 'rackhacks'
require 'streamroller'

additional_mime = {".flac" => "audio/x-flac"}
Rack::Mime::MIME_TYPES.merge!(additional_mime)

require 'RMagick'
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

m = StreamRoller::StreamRoller.new

r = HackBuilder.new do
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

