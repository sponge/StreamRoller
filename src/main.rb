$:.push("src/")

require 'rubygems'
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

if File.exists? 'config.yml'
  $config = YAML::load_file('config.yml')
  $config['location'] += '/'
else
  puts "config.yml not found. Exiting."
  exit -1
end

def authenticate
  if $config['password']
    use Rack::Auth::Basic, "Restricted Area" do |username, password|
      $config['password'] == password
    end
  end
end

m = StreamRoller::StreamRoller.new

r = Rack::Builder.new do
  map '/get' do
    authenticate
    run m
  end

  map '/pic' do
    authenticate
    run m
  end

  map '/' do
    authenticate
    use Rack::Deflater
    run m
  end
end

puts "Starting server; http://localhost:4567"
Rack::Server.start(:app => r, :server => 'trinidad', :port => 4567)
