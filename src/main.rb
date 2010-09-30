$:.push('src/') if (File.exists? 'src/')
$:.push('lib/ruby/') if (File.exists? 'lib/ruby/')

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

puts "Starting server..."
Rack::Handler::Mongrel.run r, :Port => 4567

