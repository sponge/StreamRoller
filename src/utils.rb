module Utils
  
  require 'stringio'

  def shntool_parse(s)
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

  def test_executable_in_path(command, name=nil, report_array=nil)
    name ||= command
    
    path = nil
    search = ["", "tools/"] 
    search.each do |p|
      begin
        stdout = $stdout
        stderr = $stderr
        $stdout = StringIO.new
        $stderr = StringIO.new
        `#{p+command}`
        if $?.success?
          path = name
          break
        end
      rescue IOError
        
      ensure
        $stdout = stdout
        $stderr = stderr
      end
    end
    
    if not path.nil?
      return path
    else
      report_array << name unless report_array.nil?
      return false
    end
  end
  
  def sanitize(path)
    return '.' if path == ''
    path.chomp('/')
  end

  def trim_response(arr)
    arr = JSON.parse(arr)
    arr.each do |hash|
      hash.each do |k,v|
        hash.delete(k) if v == '' || v == nil || (k == 'folder' && v == 'f') || (k == 'art' && v == 'f')
      end
    end
    
    return arr
  end


  #use: h = recursive_dir_structure(".") for current dir
  def recursive_dir_structure(dir)
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
