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

