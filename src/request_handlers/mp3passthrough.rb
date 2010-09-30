Kernel.require 'src/abstracthandler'

module StreamRoller
  module RequestHandler
    class MP3Passthrough < AbstractHandler
      support_mimetype "audio/mpeg"
      priority 100
      
      def initialize(toolman)
        @toolman = toolman
      end
      
      def handle( sinatra_request, dbrow )
        #here is where we would determine if the client can accept mp3s
        
        f = File.new($config['location'] + dbrow[:path] + '/' + dbrow[:file])
        sinatra_request.content_type mime_type(".mp3")
        sinatra_request.attachment File.basename(dbrow[:file])
        return f
      end
    end
  end
end