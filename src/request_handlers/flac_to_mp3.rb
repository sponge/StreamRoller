require 'src/abstracthandler'
require 'src/utils'

module StreamRoller
  module RequestHandler
    class FlacToMP3 < AbstractHandler      
      support_mimetype "audio/x-flac"
      priority 50
      
      require_tool "flac"
      require_tool "lame"
      require_tool "shntool"
      
      config_name "flac_to_mp3"
      
      default_config({ "bitrate" => 128 })
      
      def handle(sinatra_request, dbrow)
        
        sinatra_request.content_type mime_type(".mp3")
        sinatra_request.attachment File.basename(dbrow[:file], ".flac") + ".mp3"
        filepath = $config['location'] + dbrow[:path] + '/' + dbrow[:file]
        shntool = @toolman.invoke("shntool", "info \"#{filepath}\"")
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
        
        sinatra_request.response['Content-length'] = size.to_s
        
        return @toolman.pipe("flac", "-s -d -c \"#{filepath}\"").pipe("lame", "--silent --cbr -b #{@config['bitrate']} - -").io
        
      end
    end
  end
end