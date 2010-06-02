require "rack"

# Herein lie hacked up rack classes that don't modify the PATH_INFO, so that
# sinatra routing will work properly. Middleware that modifies requests ftl?

# Hacked in here so that lib can be updated without merges, but the code should
# probably be checked for any relevant changes before deploying new libraries

class HackURLMap < Rack::URLMap
  def initalize(*args)
    super(*args)
  end
  
  def call(env)
    path = env["PATH_INFO"].to_s
    script_name = env['SCRIPT_NAME']
    hHost, sName, sPort = env.values_at('HTTP_HOST','SERVER_NAME','SERVER_PORT')
    @mapping.each { |host, location, match, app|
      next unless (hHost == host || sName == host \
        || (host.nil? && (hHost == sName || hHost == sName+':'+sPort)))
      next unless path =~ match && rest = $1
      next unless rest.empty? || rest[0] == ?/

      return app.call(
        env.merge(
          'SCRIPT_NAME' => (script_name + location)))
    }
    [404, {"Content-Type" => "text/plain", "X-Cascade" => "pass"}, ["Not Found: #{path}"]]
  end
end

class HackBuilder < Rack::Builder
  def initialize(*args)
    super(*args)
  end
  
  def to_app
    @ins[-1] = HackURLMap.new(@ins.last)  if Hash === @ins.last
    inner_app = @ins.last
    @ins[0...-1].reverse.inject(inner_app) { |a, e| e.call(a) }
  end
end
