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

$imgformat = "jpg"

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
Rack::Server.start(:app => r, :server => 'trinidad', :port => 4567)
