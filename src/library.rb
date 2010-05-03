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
      'id3_date' => FieldKey::YEAR
    }.each do |k,v|
      tags[k] = tag.getFirst(v)
    end
    tags['length'] = af.getAudioHeader().getTrackLength();
    return tags
  end
  
  def scan(dir)
    beginTime = Time.now.to_i
    
    Song.delete_all
    Dir.chdir(dir) do
      files = []
      Dir['{**/*/,**/*.mp3}'].each do |file|
        files.push(file)
      end
      
      len = files.length
      ActiveRecord::Base.transaction do
        files.each_index do |i|
          puts i.to_s + '/' + len.to_s if (i % 100 == 0)
          
          file = files[i]
          fields = {}
          
          begin
            if !File.directory?(file) 
              fields.merge!( get_tags( read_file(dir + file) ) )
            end
          rescue
            puts "error getting id3 tag: #{file}"
          end
          
          begin
            fields.merge!({ 'folder' => File.directory?(file), 'path' => File.dirname(file), 'file' => File.basename(file) })
            Song.create(fields)
          rescue
            puts "error adding file or folder: #{file} (#{$!})"
            next
          end
        end
      end
      
      scantime = (Time.now.to_i - beginTime)
      sps = len / scantime
      puts "Took #{scantime.to_s} seconds to scan #{len.to_s} songs. (#{sps.to_s} songs per second)"
    end
  end
  
  def scan_album_art(base)
    songs = Song.find(:all, :conditions => { :art => nil, :folder => 'f' })
    songs.each do |song|      
      begin
        art = read_file(base + song.path.to_s + '/' + song.file.to_s).getTag().getFirstArtwork()
        if (art)
          m = java.security.MessageDigest.getInstance('MD5')
          m.update(art.getBinaryData())
          md5 = java.math.BigInteger.new(m.digest()).toString(16).slice(-8,8)
          ext = art.getMimeType().to_s.split('/')[1]
          filename = "#{md5}.#{mime}"
          Song.update(song.id, :art => ext)
          if (!File.exists? "art/#{filename}")
            f = java.io.File.new("art/#{filename}")
            fos = java.io.FileOutputStream.new(f)
            fos.write(art.getBinaryData())
            fos.flush()
            fos.close()
          end
        end
      rescue
        puts "Error scanning album art: #{$!}"
      end
    end
  end
  
end
