module StreamRoller
  module RequestHandler
    # http://railstips.org/blog/archives/2006/11/18/class-and-instance-variables-in-ruby

    module ClassLevelInheritableAttributes
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def inheritable_attributes(*args)
          @inheritable_attributes ||= [:inheritable_attributes]
          @inheritable_attributes += args
          args.each do |arg|
            class_eval %(
              class << self; attr_accessor :#{arg} end
            )
          end
          @inheritable_attributes
        end

        def sub_inherited(subclass)
          if not @inheritable_attributes.nil?
            @inheritable_attributes.each do |inheritable_attribute|
              instance_var = "@#{inheritable_attribute}"
              begin
                new_instance_var = instance_variable_get(instance_var).clone
              rescue TypeError
                new_instance_var = instance_var
              end
              subclass.instance_variable_set(instance_var, new_instance_var)
            end
          end
        end
      end
    end

    class AbstractHandler
      include ClassLevelInheritableAttributes

      @required_tools = []
      @priority = -1
      @input_mimetype = nil
      @output_mimetype = nil
      @config_name = nil
      @default_config = {}

      inheritable_attributes :input_mimetype, :output_mimetype, :priority, :required_tools, :config_name, :default_config

      @handlers = []

      class << self
        def require_tool(toolname)
          @required_tools << toolname
        end

        def priority(p=nil)
          @priority = p unless p.nil?
          return @priority
        end

        def input_mimetype(mimetype)
          raise ArgumentError, "Input mimetype can only be set once! Was already set to #{@input_mimetype}" unless @input_mimetype == "@input_mimetype"
          @input_mimetype = mimetype
        end

        def output_mimetype(mimetype)
          raise ArgumentError, "Output mimetype can only be set once! Was already set to #{@output_mimetype}" unless @output_mimetype == "@output_mimetype"
          @output_mimetype = mimetype
        end

        def supported_input
          return @input_mimetype
        end

        def supported_output
          return @output_mimetype
        end

        def required_tools
          return @required_tools
        end

        def defined_handlers
          return @handlers
        end

        def add_handler(h)
          @handlers << h
        end

        def config_name(c=nil)
          @config_name = c unless c.nil?
          return @config_name
        end

        def default_config(h=nil)
          @default_config = h unless h.nil?
          return @default_config
        end

      end

      def priority
        raise RuntimeError, "#priority called on Abstract Handler"
      end

      def initialize(toolman, config)
        @toolman = toolman
        @config = config
      end

      def self.inherited(subclass)
        self.add_handler(subclass)
        self.sub_inherited(subclass)
      end

      def handle_request(sinatra_response, dbrow)
        @response = sinatra_response
        if sinatra_response.params[:supported_mimetypes]
          return nil unless sinatra_response.params[:supported_mimetypes].include?(self.class.supported_output)
        end
        @dbrow = dbrow
        @filepath = $config['location'] + @dbrow[:path] + '/' + @dbrow[:file]
        @filename = @dbrow[:file]
        handle
      end
    end
  end
end
