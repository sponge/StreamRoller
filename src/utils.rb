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
      arr = JSON.parse(arr)
      arr.each do |hash|
        hash.each do |k,v|
          hash.delete(k) if v == '' || v == nil || (k == 'folder' && v == 'f') || (k == 'art' && v == 'f')
        end
      end
      
      return arr
    end
  
    #use: h = recursive_dir_structure(".") for current dir
    def self.recursive_dir_structure(dir)
      structure = {}
      Dir.chdir(dir) do
        current = Dir["*"]
        current.each do |c|
          if File.directory?(c)
            structure[c] = recursive_dir_structure(c)
          end
        end
      end
      return structure
    end
  
  end
end
