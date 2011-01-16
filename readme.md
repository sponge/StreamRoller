StreamRoller
============
Never be caught rolling without your tunes again!  

StreamRoller is a web-server for desktops that serves your music collection to any web browser that supports HTML5 audio or Flash. StreamRoller supports most modern browsers, and should work on iOS and Android devices. The server should run on any platform that supports Java, although only desktops have been tested.

The StreamRoller server is powered by the excellent [Sinatra](http://www.sinatrarb.com/) framework for web applications, and uses [Rawr](http://rawr.rubyforge.org/) for packaging the entire app up in a redistributable package. The entire stack runs on top of [JRuby](http://jruby.org/). a Ruby implementation in Java in order to easily run on many platforms. The front-end uses [JPlayer](http://www.happyworm.com/jquery/jplayer/) in order to provide audio with Flash fallback.

Running
-------
StreamRoller is not yet as user-friendly as it is intended to be, however setting it up should be fairly straight forward.

**Note:** On Mac OS X, config.yml.example is located inside the app bundle, at StreamRoller.app/Contents/Resources/Java

1. Rename `config.yml.example` to `config.yml`
2. Open `config.yml` in a text-editor (Notepad, nano)
3. Change `location:` to point to your music collection.
4. Optionally, set `skip_discovery: false` to force StreamRoller to rebuild your collection and find new songs.
5. Run `StreamRoller.exe` (Windows), `StreamRoller.app` (OS X), `java -jar StreamRoller.jar` (all others)

StreamRoller will require a port to be opened on your firewall. By default, StreamRoller will attempt to use HTTP traffic over TCP port 4567 for all communications.


Building
--------
If JRuby is installed on the local system, you can run the application without building a JAR. Just run `streamroller.bat` in the root directory of the project.

1. Download and install JRuby. Streamroller has been tested with JRuby 1.5.2.
2. Install the `rawr` gem (`jgem install rawr`)
3. Build a JAR using `rake rawr:jar`
4. Copy the `public` directory into package\jar
5. Optionally bundle the Windows or OS X binaries using `rake rawr:bundle:exe` and `rake rawr:bundle:app`

(**Note:** Due to an issue, currently either streamroller.rb or streamroller.class must be manually extracted into the same directory as the JAR file.)

Known Issues
------------
* Server: Running StreamRoller from a JAR on Windows requires that the streamroller.class be present in the same directory as the JAR.
* Server: Transcoding is not yet documented, and may be buggy.
* Server: Does not currently handle Unicode file names. This seems to be an issue with JRuby's Ruby 1.8 implementation. (ex. M.C.D.EAD - ? ??????? will not show up)
* Client: Playlists are buggy. This will be resolved when the web UI is overhauled.
* Client: Songs sometimes freeze despite enough buffer being available. This appears to occur when using the Flash Player fallback. To work around this, you can either wait for the song to finish downloading, and click on it in the playlist to restart, or you can create an M3U playlist from the Playlist drop-down menu and use an external media player.

Limitations
-----------
* Server: The library must manually be reset by either setting `skip_discovery: false` or deleting library.sqlite in order to detect new music.
