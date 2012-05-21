require 'abstracthandler'
require 'utils'

module StreamRoller
  module RequestHandler
    class FlacToOgg < AbstractHandler
      input_mimetype "audio/x-flac"
      output_mimetype "audio/ogg"

      require_tool "vorbis"

      config_name "flac_to_ogg"

      def handle
        set_sinatra_http_response_properties
        return transcode_flac_to_ogg
      end

      def priority
        75
      end

      private

      def set_sinatra_http_response_properties
        @response.content_type mime_type(".ogg")
        @response.attachment File.basename(@filename, ".flac") + ".ogg"
      end

      def transcode_flac_to_ogg
        @toolman.pipe("vorbis", "-Q -o - \"#{@filepath}\"").io
      end
    end
  end
end
