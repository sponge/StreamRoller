require 'rubygems'
require 'jdbc/sqlite3'
require 'sequel'
require 'sinatra'
require 'yaml'
require 'pp'
require 'json'
require 'timeout'

require 'java'
import 'org.sqlite.JDBC'

$:.push('src/') if (File.exists? 'src/')
require 'utils'
require 'library'
require 'toolmanager'
require 'requestrouter'

class Song
  def to_json
    to_s.to_json
  end
end
class Sequel::Dataset
  def to_json
    naked.all.to_json
  end
end
class Sequel::Model
  def self.to_json
    dataset.to_json
  end
end

module StreamRoller
  
  class StreamRoller < Sinatra::Base
    
    set :static, true
    set :public, 'public/'
    set :sessions, true
    
    def initialize
      super
      
      # check environment
      if File.exists? 'config.yml'
        $config = YAML::load( File.open('config.yml') )
        $config['location'] += '/'
      else
        puts "config.yml not found. Exiting."
        exit -1
      end
      
      $db = Sequel.connect("jdbc:sqlite:#{$config['db']}")
      
      # library generation
      if !$db.table_exists?(:songs) or !$config['skip_discovery']
        puts "Table not found, creating and forcing library discovery" if !$db.table_exists?(:songs)
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
        Library::scan($config['location'])
      end
      
      FileUtils.mkdir('art') if !File.directory?('art')
      if (!$config['skip_album_art'])
        Thread.new do
          Library::scan_album_art($config['location'])
        end
      end
      
      @toolmanager = ToolManager.new
      @streamrouter = RequestRouter.new(@toolmanager)
      
      puts "Tools discovered:"
      puts @toolmanager.available_tools.join(", ")
      
      puts "Supported mimetypes:"
      puts @streamrouter.handled_mimetypes.join(", ")
    end
    
    get '/' do
      send_file 'public/index.html'
    end
    
    get '/list/?*/?' do
      Timeout.timeout(10) do
        path = Utils::sanitize params[:splat].join('')   
        redirect('/#'+path) if !request.xhr?
        
        mimetype_list = @streamrouter.handled_mimetypes.map{|x| "\"#{x}\""}.join(", ")
        files = $db.fetch("SELECT * FROM songs WHERE path = ? AND (mimetype IN(#{mimetype_list}) OR folder = 't') ORDER BY folder DESC, id3_track, file", path)
        
        json = Utils::trim_response(files.to_json).to_json
        
        return "#{params[:callback]}(#{json})" if params[:callback]
        return json
      end
    end
    
    get '/browse/?' do
      Timeout.timeout(10) do
        whereartist = (!params[:artist].to_s.empty?) ? 'WHERE id3_artist = :artist ' : ''
        
        artists = Song.find_by_sql('SELECT DISTINCT id3_artist FROM songs ORDER BY id3_artist').map(&:id3_artist)
        albums = Song.find_by_sql([ 'SELECT DISTINCT id3_album FROM songs ' + whereartist + 'ORDER BY id3_album', {:artist => params[:artist]} ]).map(&:id3_album)
        songs = []
        if ( !params[:artist].to_s.empty? || !params[:album].to_s.empty? )
          cond = {}
          cond[:id3_artist] = params[:artist] if !params[:artist].to_s.empty?
          cond[:id3_album] = params[:album] if !params[:album].to_s.empty?
          songs = Song.find(:all, :select => 'id, id3_title', :conditions => cond, :order => 'folder, id3_track, file ')
        end
        
        { :artists => artists, :albums => albums, :songs => songs }.to_json;
      end
    end
    
    get '/get/:id' do
      f = @streamrouter.route(self)
      halt f.read()
      f.close()
    end
    
    get '/pic/:id' do
      Timeout.timeout(10) do
        f = $db[:songs].filter(:id => params[:id]).first()
        return false if f[:art] == 'f'
        begin
          send_file "art/#{f[:art]}"
        rescue
          puts "Error sending album art: #{$!}"
        end
      end
    end
    
    get '/m3u' do
      content_type 'application/x-winamp-playlist'
      attachment 'playlist.m3u'
      session[:playlist]
    end
    
    post '/m3u' do
      session[:playlist] = params[:playlist]
    end
    
    get '/*' do
      redirect '/#'+params[:splat][0]
    end  
  end
end