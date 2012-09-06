angular.module('streamroller', ['player']).config(['$routeProvider', function($routeProvider) {
  $routeProvider.
      when('/playlist', {templateUrl: '/playlistview.html', controller: PlaylistCtrl}).
      when('/:artist', {templateUrl:'/detailview.html', controller: ArtistDetailCtrl}).
      when('/:artist/:album', {templateUrl:'/detailview.html', controller: ArtistDetailCtrl}).
      otherwise({redirectTo: '/'});
}]);

angular.module('player', [], function($provide) {
  // audio player module
  $provide.factory('$player', function($rootScope) {
    var srv = {};

    // handle to currently playing soundManager handle
    srv.nowPlaying = undefined;
    srv.song = undefined;
    srv.paused = true;

    // destroy the current handle and start playing the requested song
    // song is a JSON object containing all the song info
    srv.play = function( song ) {
      if ( srv.nowPlaying ) {
        srv.nowPlaying.destruct();
      }

      srv.nowPlaying = soundManager.createSound({
        id: 'audio',
        url: '/get/'+ song.id,
        autoLoad: true,
        autoPlay: true,
        whileplaying: function() {
          // FIXME: bad place to update progress
          $('.player .progress .bar').css('width', (this.position / this.duration * 100) + '%')
        }
      });

      srv.song = song;
      srv.paused = false;

      $rootScope.$broadcast('playerChanged');

    };

    srv.togglePause = function() {
      if ( srv.nowPlaying ) {
        srv.nowPlaying.togglePause();
        srv.paused = srv.nowPlaying.paused;
        $rootScope.$broadcast('pauseChanged');
      }
    };

    srv.changeVolume = function(amt) {
      if ( srv.nowPlaying ) {
        amt = Math.max(0, Math.min(100, srv.nowPlaying.volume + amt));
        srv.nowPlaying.setVolume( amt );
      }
    }

    return srv;
  });

  // playlist module
  $provide.factory('$playlist', function($rootScope) {
    var srv = {};

    srv.playlist = [];

    srv.queue = function( msg ) {
      srv.playlist.push( msg );
    };

    return srv;
  });
});

soundManager.setup({
  url: '/swf/',
  onready: function() {
    console.log('Ready to play sound!');
  },
  ontimeout: function() {
    console.log('SM2 start-up failed.');
  },
  defaultOptions: {
    volume: 50
  }
});

// FIXME: need to kill the default beavhior here
jQuery( function($) {
  $('.albumList').on('click', '.album ul li a', function(e) {
    return false;
  });
});
