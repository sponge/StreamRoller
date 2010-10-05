module StreamRoller
  module Utils
  
  require 'stringio'
  
    def self.shntool_parse(s)
    sio = StringIO.new(s)
    params = {}
    (1..5).each do |x|
      cur = sio.readline()
      next if cur.index(":").nil?
      cur.chomp!
      a = cur.partition(":")
      params[a[0]] = a[2].lstrip
    end
    
    return params
  end
    
    def self.sanitize(path)
    return '.' if path == ''
    path.chomp('/')
  end
  
  def self.trim_response(arr)
    
    arr.each do |hash|
      hash.delete_if {|k,v| v == '' or v.nil? }
    end
    
    return arr
  end
  
  #use: h = recursive_dir_structure(".") for current dir
    def self.recursive_dir_structure(dir)
    structure = {}
    Dir.chdir(dir) do
      current = Dir["*"]
      current.each do |c|
        begin
          if File.directory?(c)
            structure[c] = recursive_dir_structure(c)
          end
        rescue
        end
      end
    end
    return structure
  end
  
  end
end
