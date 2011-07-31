require 'abstracthandler'

module StreamRoller
  module RequestHandler
    class MP3Passthrough < AbstractHandler
      support_mimetype "audio/mpeg"
      priority 100
      config_name "mp3passthrough"
      
      def handle
        #here is where we would determine if the client can accept mp3s
        
        f = Sinatra::Helpers::StaticFile.new(@filepath, 'rb')
        @response.content_type mime_type(".mp3")
        @response.attachment @filename
        @response.response['Content-length'] = File.size(@filepath).to_s
        return f
      end
    end
  end
end
