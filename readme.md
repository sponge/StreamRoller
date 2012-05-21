StreamRoller
============
Never be caught rolling without your tunes again!  

StreamRoller is a web-server for desktops that serves your music collection to any web browser that supports mp3 HTML5 audio (Chrome, IE9, and Safari, at the time of writing). Transcoding from FLAC to vorbis & mp3 is supported. Additional transcoding options may be added in the future.

A client is in development for android, and is planned for iOS and Windows phone. The server should run on any platform that supports Java, although only Linux and Windows have been tested.

The StreamRoller server is powered by [Sinatra](http://www.sinatrarb.com/) on top of [JRuby](http://jruby.org/).

Running
-------
StreamRoller is not yet as user-friendly as it is intended to be, however setting it up should be fairly straight forward.

1. Rename `config.yml.example` to `config.yml`
2. Open `config.yml` in a text-editor (Notepad, nano)
3. Change `location:` to point to your music collection.
4. Optionally, uncomment the `password:` field and change the value to set a password.
5. Run streamroller.jar 

StreamRoller will require a port to be opened on your firewall. By default, StreamRoller will attempt to use HTTP traffic over TCP port 4567 for all communications.

Tools
--------
In order to transcode, StreamRoller requires external programs. These can be provided by the system, or placed inside the `tools/` directory of the distribution.

* FLAC to mp3 support requires `flac` and `lame`
* FLAC to Vorbis support requires `oggenc` or `oggenc2`

Building
--------

1. Install a JDK http://www.oracle.com/technetwork/java/javase/downloads/index.html
1. Download and install JRuby.
1. Install bundler: `jgem install bundler`
1. Start the build process: `jruby -S rake build`

Known Issues
------------
* Server: Does not currently handle Unicode file names. This seems to be an issue with JRuby's Ruby 1.8 implementation. (ex. M.C.D.EAD - ? ??????? will not show up)
* Client: Playlists are buggy. This will be resolved when the web UI is overhauled.

Limitations
-----------
* Server: The library must manually be reset by either setting `skip_discovery: false` or deleting library.sqlite in order to detect new music.
