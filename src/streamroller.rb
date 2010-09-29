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
    return $db[:songs].filter(:path.like("#{path}%")).filter(:folder => "f").order(:id3_date).order_more(:id3_album).order_more(:id3_track).order_more(:id3_title).order_more(:file)
  else
    return $db[:songs].filter(:path.like("#{path}%")).filter(:folder => "f").filter({:mimetype => "audio/mpeg"} | {:folder => true}).order(:id3_date).order_more(:id3_album).order_more(:id3_track).order_more(:id3_title).order_more(:file)
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
  failures = []
  #test for all of the needed commandline utilities
  $flac = test_executable_in_path("flac", nil, failures)
  $shntool = test_executable_in_path("shntool -h", "shntool", failures)
  $lame = test_executable_in_path("lame --help", "lame", failures)
  
  if failures.empty?
    $transcoding = true
  else
    puts "At least one transcoding tool was not found. Consult the readme for details about installing:"
    puts failures.join(", ")
  end
  
end

if $transcoding and $config['vorbis']
  
  tests = [["oggenc2 -h", "oggenc2"], ["oggenc -h", "oggenc"]]

  result = false
  tests.each do |t|
    $oggenc = test_executable_in_path(*t)
    if $oggenc != false
      break
    end
  end

  if $oggenc != false
    $vorbis = true
  else
    puts "A vorbis encoding tool was not found. Consult the readme."
  end
end

FileUtils.mkdir('art') if !File.directory?('art')
Thread.new { Library::scan_album_art($config['location']) } if (!$config['skip_ablum_art'])

# =============
#  main routes
# =============

class StreamRoller < Sinatra::Base
  
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
  
  get '/get/:id' do
    Dir.chdir("tools") do |dir|
      # find song, send file if mp3, transcode & send if flac
      
      Timeout.timeout(10) do
        f = $db[:songs].filter(:id => params[:id]).first()
        filepath = $config['location'] + f[:path] + '/' + f[:file]
		
		#log song to console: m/d hh:mm:ss REMOTE_ADDR: title - artist or filename
		puts "#{Time.new.strftime("%m/%d %H:%M:%S")} #{request.env['REMOTE_ADDR']}: #{( (f[:id3_artist] && f[:id3_title] ) ? "#{f[:id3_artist]} - #{f[:id3_title]}" : f[:file])}"
		
        if File.extname(filepath) == ".flac" and $transcoding
          if params[:external] == "true"
            if $vorbis
              content_type mime_type(".ogg")
              attachment File.basename(filepath, ".flac") + ".ogg"
              halt StaticFile.popen("#{$oggenc} -Q -q#{$config["vorbis_quality"]} -o - \"#{filepath}\"")
            else
              content_type mime_type(".mp3")
              attachment File.basename(filepath, ".flac") + ".mp3"
              halt StaticFile.popen("#{$flac} -s -d -c \"#{filepath}\" | #{$lame} --silent #{$config["lame_external_options"]} - -")
            end
          else
            content_type mime_type(".mp3")
            attachment File.basename(filepath, ".flac") + ".mp3"
            command = "#{$shntool} info \"#{filepath}\""
            shntool = File.popen(command)
            shnput = shntool.read()
            data = shntool_parse(shnput)
            
            length = data["Length"]
            p = length.partition(":")
            minutes = p[0].to_i
            seconds = p[2].partition(".")[0].to_i
            ms = p[2].partition(".")[2].to_i
            total = ms + seconds * 1000 + minutes * 60 * 1000
            size = total * $config['transcode_bitrate'].to_i
            size = (size.to_f / 8.0).ceil
            response['Content-length'] = size.to_s
            command = "#{$flac} -s -d -c \"#{filepath}\" | #{$lame} --silent --cbr -b #{$config['transcode_bitrate']} - -"
            halt StaticFile.popen(command)
          end
        else
          send_file filepath, :filename => f[:file]  
        end
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

  get '/dirs/?*/?' do
    Timeout.timeout(10) do
      path = "#{$config['location']}/#{Utils::sanitize params[:splat].join('')}"
      Utils.recursive_dir_structure(path).to_json
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
