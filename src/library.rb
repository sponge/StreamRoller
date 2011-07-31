require 'java'
require 'lib/jaudiotagger-2.0.2.jar'

module StreamRoller
  module Library
  
    import 'org.jaudiotagger.audio.AudioFileIO'
    import 'org.jaudiotagger.tag.FieldKey'
    
    def self.read_file(location)
      return AudioFileIO.read(java.io.File.new(location))
    end
    
    def self.get_tags(af)
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
    
    def self.scan(dir)    
      beginTime = Time.now.to_i
      
      songs = $db[:songs]
      Dir.chdir(dir) do
        #TODO: This glob should really be built dynamically! Every handler should register some extensions. It doesn't matter if that handler actually works at the time, since the mimetypes are filtered at runtime. But at library-build time, we should add the tags for everything that can potentially be played.
        files = Dir['{**/*/,**/*.mp3,**/*.flac}']
        
        len = files.size
        $db.transaction do
          files.each_with_index do |file, i|
            puts "#{i.to_s}/#{len.to_s} songs scanned" if (i % 100 == 0)
            
            fields = {}
            
            begin
              if !File.directory?(file) 
                fields.merge!( get_tags( read_file(dir + file) ) )
                fields["mimetype"] = mime_type(File.extname(file))
              end
            rescue
              puts "error getting id3 tag: #{file}"
            end
            
            begin
              fields.merge!({ 'folder' => File.directory?(file), 'path' => File.dirname(file), 'file' => File.basename(file) })
              songs << fields
            rescue
              puts "error adding file or folder: #{file} (#{$!})"
              next
            end
          end
        end
        
        scantime = (Time.now.to_i - beginTime)
        if scantime == 0
          sps = 0
        else
          sps = len / scantime
        end
        
        puts "Took #{scantime.to_s} seconds to scan #{len.to_s} songs. (#{sps.to_s} songs per second)"
      end
    end
    
    def self.scan_album_art(base)
      songs = $db[:songs].where(:art => nil, :folder => 'f')
      songs.all do |song|      
        begin
          art = read_file(base + song[:path] + '/' + song[:file]).getTag().getFirstArtwork()
          if (art)
            m = java.security.MessageDigest.getInstance('MD5')
            m.update(art.getBinaryData())
            md5 = java.math.BigInteger.new(m.digest()).toString(16).slice(-8,8)
            ext = art.getMimeType().to_s.split('/')[1]
            filename = "#{md5}.#{ext}"
            
            $db[:songs].filter(:id => song[:id]).update(:art => filename)
            
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
end
