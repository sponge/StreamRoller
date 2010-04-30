module Library

  import 'org.jaudiotagger.audio.AudioFileIO'
  import 'org.jaudiotagger.tag.FieldKey'
  
  def read_file(location)
    return AudioFileIO.read(java.io.File.new(location))
  end
  
  def get_tags(af)
    tag = af.getTag()
    tags = {}
    {
      'id3_track' => FieldKey::TRACK,
      'id3_artist' => FieldKey::ARTIST,
      'id3_album' => FieldKey::ALBUM,
      'id3_title' => FieldKey::TITLE,
      'id3_date' => FieldKey::YEAR,
    }.each do |k,v|
      tags[k] = tag.getFirst(v)
    end
    
    return tags
  end
  
  def scan(dir)
    beginTime = Time.now.to_i
    
    Song.delete_all
    Dir.chdir(dir)
    files = []
    Dir['{**/*/,**/*.mp3}'].each do |file|
      files.push(file)
    end
    
    len = files.length
    files.each_index do |i|
      puts i.to_s + '/' + len.to_s if (i % 100 == 0)
      
      file = files[i]
      fields = {}
      
      begin
        if !File.directory?(file) 
          fields.merge!( get_tags( read_file(dir + file) ) )
        end
      rescue
        puts "error getting id3 tag: "+ file
      end
      
      begin
        fields.merge!({ 'folder' => File.directory?(file), 'path' => File.dirname(file), 'file' => File.basename(file) })
        
        s = Song.new(fields)
        s.save
      rescue
        puts "error adding file or folder: "+ file
        next
      end
    end
    
    scantime = (Time.now.to_i - beginTime)
    sps = len / scantime
    puts 'Took ' + scantime.to_s + ' seconds to scan ' + len.to_s + ' songs. (' + sps.to_s + ' songs per second)'
  end
  
end
