module Utils
  
  require 'open3'
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

  #returns the error status
  def test_executable_in_path(name)
    stdin, stdout, stderr = Open3.popen3(name)
    if stdout.eof? and stderr.eof?
      puts "#{name} not found in path, cannot enable transcoding"
      return true
    end
    return nil
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

end
