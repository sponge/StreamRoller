require 'abstracthandler'
require 'utils'

module StreamRoller
  module RequestHandler
    class FlacToMP3 < AbstractHandler
      input_mimetype "audio/x-flac"
      output_mimetype "audio/mpeg"

      require_tool "flac"
      require_tool "lame"

      config_name "flac_to_mp3"

      def handle
        set_sinatra_http_response_properties
        return transcode_flac_to_mp3
      end

      def priority
        50
      end

      private

      def set_sinatra_http_response_properties
        @response.content_type mime_type(".mp3")
        @response.attachment File.basename(@filename, ".flac") + ".mp3"
      end

      def transcode_flac_to_mp3
        @toolman.pipe("flac", "-s -d -c \"#{@filepath}\"").pipe("lame", "--silent --preset standard - -").io
      end
    end
  end
end
