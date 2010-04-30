module Utils
  
  def sanitize(path)
    return '.' if path == ''
    path.chomp('/')
  end

  def trim_response(arr)
    # FIXME: this is really stupid - strip values that are blank or default
    arr = JSON.parse(arr.to_json)
    arr.each do |hash|
      hash.each do |k,v|
        hash.delete(k) if v == '' || v == nil || (k == 'folder' && v == 'f')
      end
    end
    
    return arr
  end

end
