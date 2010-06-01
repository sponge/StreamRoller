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
  if $transcoding
    return $db[:songs].filter(:path => path).order(:folder.desc).order_more(:id3_track).order_more(:file)
  else
    return $db[:songs].filter(:path => path).filter({:mimetype => "audio/mpeg"} | {:folder => true}).order(:folder.desc).order_more(:id3_track).order_more(:file)
  end
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
    String :mimetype
  end
  Library::scan($config['location'])
end

$transcoding = false
$vorbis = false

if $config['transcoding']
  fail = nil
  #test for all of the needed commandline utilities
  fail ||= test_executable_in_path("flac")
  fail ||= test_executable_in_path("shntool")
  fail ||= test_executable_in_path("lame")
  if not fail
    $transcoding = true
  end
end

if $transcoding and $config['vorbis']
  result = test_executable_in_path("oggenc2")
  if result == nil
    $vorbis = true
  end
end

FileUtils.mkdir('art') if !File.directory?('art')
Thread.new { Library::scan_album_art($config['location']) } if (!$config['skip_ablum_art'])

# =============
#  main routes
# =============

class MediaStreamer < Sinatra::Base
  
  set :static, true
  set :public, 'public/'
  set :sessions, true
  
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
  
  get '/get/:id' do
    # find song, send file if mp3, transcode & send if flac
    
    Timeout.timeout(10) do
      f = $db[:songs].filter(:id => params[:id]).first()
      filepath = $config['location'] + f[:path] + '/' + f[:file]
      
      if File.extname(filepath) == ".flac" and $transcoding
        if params[:external] == "true"
          if $vorbis
            content_type mime_type(".ogg")
            attachment File.basename(filepath, ".flac") + ".ogg"
            halt StaticFile.popen("oggenc2 -Q -q#{$config["vorbis_quality"]} -o - \"#{filepath}\"")
          else
            content_type mime_type(".mp3")
            attachment File.basename(filepath, ".flac") + ".mp3"
            halt StaticFile.popen("flac -s -d -c \"#{filepath}\" | lame --silent #{$config["lame_external_options"]} - -")
          end
        else
          content_type mime_type(".mp3")
          attachment File.basename(filepath, ".flac") + ".mp3"
          shntool = File.popen("shntool info \"#{filepath}\"")
          shnput = shntool.read()
          data = shntool_parse(shnput)
          
          length = data["Length"]
          p = length.partition(":")
          minutes = p[0].to_i
          seconds = p[2].partition(".")[0].to_i
          ms = p[2].partition(".")[2].to_i
          total = ms + seconds * 1000 + minutes * 60 * 1000
          #frames = total.to_f / 26
          #size = frames * 417.96
          size = total * $config['transcode_bitrate'].to_i
          size = (size.to_f / 8.0).ceil
          response['Content-length'] = size.to_s
          halt StaticFile.popen("flac -s -d -c \"#{filepath}\" | lame --silent --cbr -b #{$config['transcode_bitrate']} - -")
        end
      else
        send_file filepath, :filename => f[:file]  
      end
    end
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
  self.run!
  
end

MediaStreamer.new