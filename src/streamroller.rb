require 'rubygems'
require 'jdbc/sqlite3'
require 'sequel'
require 'sinatra'
require 'yaml'
require 'pp'
require 'json'
require 'timeout'
require 'RMagick'

require 'java'
import 'org.sqlite.JDBC'

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
        
        files = $db[:songs].select(:id, :path, :length, :file, :id3_artist, :id3_track, :id3_album, :id3_title, :id3_date).filter(:path.like("#{path}%")).filter(:folder => false).filter(:mimetype => @streamrouter.handled_mimetypes).order(:id3_date.asc).order_more(:id3_album).order_more(:id3_track).order_more(:id3_title).order_more(:file)
        
        json = Utils::trim_response(files.all).to_json
        
        return "#{params[:callback]}(#{json})" if params[:callback]
        return json
      end
    end
    
    get '/get/:id' do
      f = @streamrouter.route(self)
      halt f
    end
    
    def cached_pic(id, size)
      size = size.to_i
      f = $db[:songs].filter(:id => id).first()
      
      uncached_path = "art/#{f[:art]}"
      
      return false if f[:art].nil? or f[:art] == 'f'
      return false if not File.exists?(uncached_path)
      
      if $config['cache_thumbnails']
        begin
          Dir.mkdir("art/#{size}")
        rescue Errno::EEXIST
        end
        
        path = "art/#{size}/#{id}.#{$imgformat}"
        if File.exists?(path)
          return File.new(path).read
        end
        
        cached = File.new(path, "w")
        converted = convert_pic(uncached_path, size)
        cached.write(converted)
        cached.close
        
        return converted
      end
      
      return convert_pic(uncached_path, size)
    end
    
    def convert_pic(path, size)
      i = Magick::Image.read(path)[0]
      r = i.resize(size,size)
      r.format = $imgformat
      content_type mime_type($imgformat)
      s = r.to_blob
      return s
    end
    
    #TODO: Maybe there's a better way to do optional params with sinatra.
    def handle_pic(id, size=96)
      size = size.to_i
      Timeout.timeout(10) do
        begin
          pic = cached_pic(id, size)
          return pic if pic
          #else
          redirect '/placeholder.png'
        rescue
          puts "Error sending album art: #{id} #{$!}"
        end
      end
    end
    private :handle_pic
    
    get '/pic/:id/?' do
      return handle_pic(params[:id])
    end
    
    get '/pic/:id/:size/?' do
      return handle_pic(params[:id], params[:size])
    end
    
    get '/dirs/?*/?' do
      Timeout.timeout(10) do
        path = "#{$config['location']}/#{Utils::sanitize params[:splat].join('')}"
        Utils.recursive_dir_structure(path).to_json
      end
    end
    
    get '/artists/?' do
      structure = {}
      rows = $db.fetch("SELECT DISTINCT id3_artist, id3_album FROM songs WHERE folder = 'f'")
      rows.each do |r|
        if structure[r[:id3_artist]] == nil
          structure[r[:id3_artist]] = []
        end
        structure[r[:id3_artist]].push r[:id3_album]
      end
  
      structure.to_json
    end
    
      # Get a list of artists and all subalbums
  
    BrowseSelect = [:id, :path, :file, :length, :art, :id3_track, :id3_artist, :id3_album, :id3_title, :id3_date, :mimetype]

    get '/browse/:artist/?' do
      files = $db[:songs].select(*BrowseSelect)
      files = files.filter(:id3_artist => params[:artist]).filter({:mimetype => @streamrouter.handled_mimetypes} | {:folder => true}).order(:id3_date).order_more(:id3_album).order_more(:id3_track).order_more(:id3_title).order_more(:file)
      json = Utils::trim_response(files.all).to_json
      return json
    end
  
    get '/browse/:artist/:album/?' do
      files = $db[:songs].select(*BrowseSelect)
      
      if (params[:artist] != "*")
        files = files.filter(:id3_artist => params[:artist])
      end
      
      files = files.filter(:id3_album => params[:album]).filter({:mimetype => @streamrouter.handled_mimetypes} | {:folder => true}).order(:id3_date).order_more(:id3_album).order_more(:id3_track).order_more(:id3_title).order_more(:file)
      json = Utils::trim_response(files.all).to_json
      return json
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

