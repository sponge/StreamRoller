module StreamRoller
  
  require 'stringio'
  
  AnnoyingSep = File::ALT_SEPARATOR.nil? ? File::SEPARATOR : File::ALT_SEPARATOR
  DefaultSearch = ["", "tools#{AnnoyingSep}"]
  
  class ToolManager
    
    class ToolPipe
      def initialize(toolman)
        @toolman = toolman
        @pipe = []
        @io = nil
      end
      
      def pipe(tool, args)
        @pipe << [tool, args]
        return self
      end
      
      def io
        cmds = []
        @pipe.each do |p|
          cmds << @toolman.commandline(p[0], p[1])
        end
        
        command = cmds.join(" | ")
        io = IO.popen(command)
        return io
      end
      
      def read(*args)

      end
      
      def close
        @io.close
        @io = nil
      end
    end
    
    def pipe(toolname, args)
      p = ToolPipe.new(self)
      p.pipe(toolname, args)
      return p
    end
    
    def initialize
      @available_tools = {}
      AbstractTool.defined_tools.each do |t|
        cur = t.new
        if cur.available?
          @available_tools[cur.name] = cur
        end
      end
    end
    
    def available_tools
      return @available_tools.keys
    end
    
    def available?(tool_name)
      return @available_tools.has_key?(tool_name)
    end
    
    def invoke(tool_name, args)
      return nil if not @available_tools.keys.include?(tool_name)
      @available_tools[tool_name].invoke(args)
    end
    
    def commandline(tool_name, args)
      return nil if not @available_tools.keys.include?(tool_name)
      return @available_tools[tool_name].commandline(args)
    end
    
  end
  
  class AbstractTool
    @@tools = []
    
    def self.defined_tools
      return @@tools
    end
    
    def self.inherited(subclass)
      @@tools << subclass
    end
    
    def initialize
      @path = nil
    end
    
    def available?
      return ! @path.nil?
    end
    
    def name
      return @name
    end
    
    def commandline(args)
      return "#{@path} #{args}"
    end
    
    def invoke(args)
      if @path.nil?
        throw RuntimeError("Tried to invoke a tool with an invalid path")
      else
        return File.popen(commandline(args))
      end
    end
    
    def test_availability
    end
    private :test_availability
    
    def test_executable_in_path(command, extra="", search=DefaultSearch)
      path = nil
      search.each do |p|
        begin
          stdout = $stdout
          stderr = $stderr
          $stdout = StringIO.new
          $stderr = StringIO.new
          `#{p+command+" "+extra}`
          if $?.success?
            path = "#{p+command}"
            break
          end
        rescue IOError
          
        ensure
          $stdout = stdout
          $stderr = stderr
        end
      end
  
      return path
    end
    private :test_executable_in_path
    
  end
  
  class FlacTool < AbstractTool
    def initialize
      super
      @name = @command = "flac"
      @path = test_executable_in_path(@command)
    end
  end
  
  class VorbisTool < AbstractTool
    def initialize
      super
      @name = "vorbis"
    end
    
    def test_availability
      path = test_executable_in_path("oggenc2")
      path = test_executable_in_path("oggenc") if path.nil?
      return path
    end
  end
  
  class ShnTool < AbstractTool
    def initialize
      super
      @name = @command = "shntool"
      @path = test_executable_in_path(@command, "-h")
    end
  end
  
  class LameTool < AbstractTool
    def initialize
      super
      @name = @command = "lame"
      @path = test_executable_in_path(@command, "--help")
    end
  end
end