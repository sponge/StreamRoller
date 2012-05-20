require "yaml"

module StreamRoller
  module InitializationHelper

    def init_database
      $db = Sequel.connect("jdbc:sqlite:#{$config['db']}")
    end

    def init_song_library
      if !$db.table_exists?(:songs) or !$config['skip_discovery']
        puts "Table not found, creating and forcing library discovery" if !$db.table_exists?(:songs)
        create_songs_table
        Library::scan($config['location'])
      end
    end

    def create_songs_table
      $db.create_table! :songs do
        primary_key :id
        String :path, :null => false
        String :file, :null => false
        boolean :folder, :default => false
        integer :length
        String :art
        integer :id3_track
        String :id3_artist
        String :id3_album
        String :id3_title
        String :id3_date
        String :mimetype
      end
    end

    def init_art
      FileUtils.mkdir('art') if !File.directory?('art')
      if (!$config['skip_album_art'])
        Thread.new do
          Library::scan_album_art($config['location'])
        end
      end
    end
  end
end
