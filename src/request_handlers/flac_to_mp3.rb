require 'abstracthandler'
require 'utils'

module StreamRoller
  module RequestHandler
    class FlacToMP3 < AbstractHandler
      input_mimetype "audio/x-flac"
      output_mimetype "audio/mpeg"
      priority 50

      require_tool "flac"
      require_tool "lame"
      require_tool "shntool"

      config_name "flac_to_mp3"

      def handle
        set_sinatra_http_response_properties
        return transcode_flac_to_mp3
      end

      private

      def set_sinatra_http_response_properties
        @response.content_type mime_type(".mp3")
        @response.attachment File.basename(@filename, ".flac") + ".mp3"
      end

      def transcode_flac_to_mp3
        @toolman.pipe("flac", "-s -d -c \"#{@filepath}\"").pipe("lame", "--silent --preset standard - -").io
      end

      def estimate_transcoded_mp3_size
        shntool = @toolman.invoke("shntool", "info \"#{@filepath}\"")
        shnput = shntool.read()
        data = Utils::shntool_parse(shnput)
        
        length = data["Length"]
        p = length.partition(":")
        minutes = p[0].to_i
        seconds = p[2].partition(".")[0].to_i
        ms = p[2].partition(".")[2].to_i
        total = ms + seconds * 1000 + minutes * 60 * 1000
        size = total * @config['bitrate'].to_i
        size = (size.to_f / 8.0).ceil
      end
    end
  end
end
