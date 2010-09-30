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
      @supported_mimetypes = []
      inheritable_attributes :supported_mimetypes, :priority, :required_tools
      
      @handlers = []
      
      class << self
        def require_tool(toolname)
          @required_tools << toolname
        end
        
        def priority(p=nil)
          @priority = p unless p.nil?
          return @priority
        end
        
        def support_mimetype(mimetype)
          @supported_mimetypes << mimetype
        end
        
        def supported_mimetypes
          return @supported_mimetypes
        end
        
        def required_tools
          return @required_tools
        end
          
        def defined_handlers
          return @handlers
        end
        
        def add_handler( h )
          @handlers << h
        end
        
      end
      
      def self.inherited(subclass)
        self.add_handler(subclass)
        self.sub_inherited(subclass)
      end
    end
  end
end