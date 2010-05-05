module Utils
  
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
