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
require 'utils'
require 'library'
include Utils, Library

# check environment
if File.exists? 'config.yml'
  $config = YAML::load( File.open('config.yml') )
  $config['location'] += '/'
else
  puts "config.yml not found. Exiting."
  exit -1
end

$db = Sequel.connect("jdbc:sqlite:#{$config['db']}")

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

def list_by_path(path)
  $db[:songs].filter(:path => path).order(:folder.desc).order_more(:id3_track).order_more(:file)
end

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
  end
  Library::scan($config['location'])
end

FileUtils.mkdir('art') if !File.directory?('art')
Thread.new { Library::scan_album_art($config['location']) } if (!$config['skip_ablum_art'])

# =============
#  main routes
# =============

class MediaStreamer < Sinatra::Base
  
  set :static, true
  set :public, 'public/'
  
  get '/' do
    send_file 'public/index.html'
  end
  
  get '/list/?*/?' do
    Timeout.timeout(10) do
      path = Utils::sanitize params[:splat].join('')   
      redirect('/#'+path) if !request.xhr?
      files = list_by_path(path)
      
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
  
  get '/get/:id' do |n|
    # find song, and just send the file
    Timeout.timeout(10) do
      f = $db[:songs].filter(:id => params[:id]).first()
      filepath = $config['location'] + f[:path] + '/' + f[:file]
      send_file filepath, :filename => f[:file]
    end
  end
  
  get '/pic/:id' do |n|
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
  
  get '/*' do
    redirect '/#'+params[:splat][0]
  end
  
  self.run!
  
end

MediaStreamer.new