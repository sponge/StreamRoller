require 'abstracthandler'

module StreamRoller
  module RequestHandler
    class MP3Passthrough < AbstractHandler
      support_mimetype "audio/mpeg"
      priority 100
      config_name "mp3passthrough"
      
      #Stolen from the Sinatra source because it's easier to do it this way than try to resolve
      #the requirement thanks to rawr, at this point (which would be Sinatra::Helpers::StaticFile)
      #TODO: Fix this if we ever figure out how to work with rawr
      class StaticFile < ::File #:nodoc:
        alias_method :to_path, :path
        def each
          rewind
          while buf = read(8192)
            yield buf
          end
        end
      end
      
      def handle( sinatra_request, dbrow )
        #here is where we would determine if the client can accept mp3s
        
        f = StaticFile.new($config['location'] + dbrow[:path] + '/' + dbrow[:file], 'rb')
        sinatra_request.content_type mime_type(".mp3")
        sinatra_request.attachment File.basename(dbrow[:file])
        sinatra_request.response['Content-length'] = File.size(f.path).to_s
        return f
      end
    end
  end
end