#\ -p 4567

require 'src/main'
require 'src/streamroller'

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

run r