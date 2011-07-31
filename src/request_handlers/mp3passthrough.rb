require 'abstracthandler'

module StreamRoller
  module RequestHandler
    class MP3Passthrough < AbstractHandler
      support_mimetype "audio/mpeg"
      priority 100
      config_name "mp3passthrough"
      
      def handle( sinatra_request, dbrow )
        #here is where we would determine if the client can accept mp3s
        
        f = Sinatra::Helpers::StaticFile.new($config['location'] + dbrow[:path] + '/' + dbrow[:file], 'rb')
        sinatra_request.content_type mime_type(".mp3")
        sinatra_request.attachment File.basename(dbrow[:file])
        sinatra_request.response['Content-length'] = File.size(f.path).to_s
        return f
      end
    end
  end
end
