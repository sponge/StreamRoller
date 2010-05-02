require 'rubygems'
require 'jdbc_adapter'
require 'sinatra'
require 'yaml'
require 'pp'
require 'json'
require 'timeout'
require 'java'
require 'lib/java/jaudiotagger-2.0.2.jar'
require 'src/utils'
require 'src/library'

include Utils, Library

# check environment
if File.exists? 'config.yml'
  config = YAML::load( File.open('config.yml') )
  config['location'] += '/'
else
  puts "config.yml not found. Exiting."
  exit -1
end

# init db
db = ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => config['db']
)

# models
class Song < ActiveRecord::Base
  def self.list_by_path(path)
    self.find(:all, :conditions => { :path => path }, :order => 'folder DESC, id3_track, id3_title, file' )
  end
end

# library generation
if !Song.table_exists? or !config['skip_discovery']
  puts "Table not found, creating and forcing library discovery" if !Song.table_exists?
  FileUtils.mkdir('art') if !File.directory?('art')
  ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS songs;')
  ActiveRecord::Base.connection.execute('
    CREATE TABLE "songs" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "path" TEXT NOT NULL,
      "file" TEXT NOT NULL,
      "folder" BOOL NOT NULL DEFAULT f,
      "length" INTEGER,
      "art" BOOL NOT NULL DEFAULT f,
      "id3_track" INTEGER,
      "id3_artist" TEXT,
      "id3_album" TEXT,
      "id3_title" TEXT,
      "id3_date" TEXT,
      "id3_pic_mime" TEXT
    )   
  ')
  Library::scan(config['location'])
end

Thread.new { Library::scan_album_art(config['location']) }

# =============
#  main routes
# =============
get '/' do
  send_file 'public/index.html'
end

get '/list/?*/?' do
  ActiveRecord::Base.clear_reloadable_connections!
  Timeout.timeout(10) do
    path = Utils::sanitize params[:splat].join('')   
    redirect('/#'+path) if !request.xhr?
    files = Song.list_by_path(path)
    
    Utils::trim_response(files).to_json;
  end
end

get '/browse/?' do
  ActiveRecord::Base.clear_reloadable_connections!
  Timeout.timeout(10) do
    whereartist = (!params[:artist].to_s.empty?) ? 'WHERE id3_artist = :artist ' : ''
    
    artists = Song.find_by_sql('SELECT DISTINCT id3_artist FROM songs ORDER BY id3_artist').map(&:id3_artist)
    albums = Song.find_by_sql([ 'SELECT DISTINCT id3_album FROM songs ' + whereartist + 'ORDER BY id3_album', {:artist => params[:artist]} ]).map(&:id3_album)
    songs = []
    if ( !params[:artist].to_s.empty? || !params[:album].to_s.empty? )
      cond = {}
      cond[:id3_artist] = params[:artist] if !params[:artist].to_s.empty?
      cond[:id3_album] = params[:album] if !params[:album].to_s.empty?
      songs = Song.find(:all, :select => 'id, id3_title', :conditions => cond, :order => 'folder, id3_track, id3_title, file')
    end
    
    { :artists => artists, :albums => albums, :songs => songs }.to_json;
  end
end

get '/get/:id' do |n|
  # find song, and just send the file
  ActiveRecord::Base.clear_reloadable_connections!
  Timeout.timeout(10) do
    f = Song.find(params[:id])
    filepath = config['location'] + f.path + '/' + f.file
    send_file filepath, :filename => f.file
  end
end

get '/pic/:id' do |n|
  ActiveRecord::Base.clear_reloadable_connections!
  Timeout.timeout(10) do
    f = Song.find(params[:id])
    headers 'Content-Type' => f.id3_pic_mime
    send_file "art/#{f.id}.#{f.id3_pic_mime.split('/')[1]}"
  end
end

get '/*' do
  redirect '/#'+params[:splat][0]
end
