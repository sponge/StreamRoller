require 'rubygems'
require 'rack'

$:.push('src/') if (File.exists? 'src/')

require 'mediastreamer'

m = MediaStreamer.new

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

Rack::Handler::Mongrel.run r, :Port => 4567
