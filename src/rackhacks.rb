# This is needed for gzip support. Rack unfortunately takes part of the path off when a middleware is invoked,
# meaning that the correct path never makes it through to Sinatra. However, we can override this sinatra method
# to tell Sinatra to rebuild the correct path from information that Rack provides.

module Sinatra
  class Request
    def route
      @route ||= Rack::Utils.unescape(script_name + path_info)
    end
  end
end
