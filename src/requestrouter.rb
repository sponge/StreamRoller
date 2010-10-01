$:.push('src/') if (File.exists? 'src/')
require 'abstracthandler'

module StreamRoller

  class RequestRouter
    def initialize(toolman = nil)
      #if toolman is nil, no toolmanager and therefore no tools are available,
      #limiting available handler to likely just passthroughs
      
      if toolman.nil?
        available_tools = []
      else
        available_tools = toolman.available_tools
      end
      
      @handlers = {}
      
      conf_handlers = $config["handlers"]
      
      RequestHandler::AbstractHandler.defined_handlers.each do |h|
        #handlers must have a configuration name
        next if h.config_name.nil?
        
        #unmentioned handlers are passed
        next if conf_handlers[h.config_name].nil?
        
        #handler must be enabled
        next if conf_handlers[h.config_name]["enabled"].nil? or conf_handlers[h.config_name]["enabled"] == false
        
        config = h.default_config.clone
        
        config.merge!(conf_handlers[h.config_name])
        
        #determine if the required tools are a subset of the available tools
        
        cont = true
        h.required_tools.each do |t|
          if !available_tools.include?(t)
            cont = false
            break
          end
        end
        
        next unless cont
        
        h.supported_mimetypes.each do |m|
          @handlers[m] ||= []
          @handlers[m] << h.new(toolman, config)
        end
      
        @handlers.each do |k,v|
          #decending order
          v.sort!{|a,b| b.priority <=> a.priority}
        end
      end
    end
    
    def handled_mimetypes
      return @handlers.keys
    end
    
    def route(sinatra_request)
      r = $db[:songs].filter(:id => sinatra_request.params[:id]).first()
      puts "#{Time.new.strftime("%m/%d %H:%M:%S")} #{sinatra_request.request.env['REMOTE_ADDR']}: #{( (r[:id3_artist] && r[:id3_title] ) ? "#{r[:id3_artist]} - #{r[:id3_title]}" : r[:file])}"
      throw RuntimeError("Unhandled mimetype! How did this happen?") unless handled_mimetypes.include?(r[:mimetype])
      
      @handlers[r[:mimetype]].each do |h|
        p = h.handle(sinatra_request, r)
        return p unless p.nil?
      end
      
      throw RuntimeError("None of the registered handlers for #{r[:mimetype]} actually handled!")
    end
  end
end

Dir["src/request_handlers/*.rb","src/request_handlers/*.class"].each do |r|
  require r
end
