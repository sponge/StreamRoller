// controller for tabbed nav
function NavigationCtrl($scope) {
  var self = this;

  // where the browse tab should link to
  $scope.url = '';
  // which button should be hilighted
  $scope.currentNav = 'browse';

  // use in the template to determine if section is active
  $scope.getClass = function(name) {
    return name == $scope.currentNav ? 'active' : ''
  };
}

// controller for player at top of page
function PlayerCtrl($scope, $player, $playlist) {
  // FIXME: should be able to do this without the broadcast, i think?
  $scope.$on('pauseChanged', function(e) {
    $scope.paused = $player.paused;
  });

  $scope.$on('playerChanged', function(e) {
    $scope.song = $player.song;
    $scope.paused = $player.paused;
  });

  $scope.togglePause = function() {
    $player.togglePause();
    $scope.paused = $player.paused;
  };

  $scope.changeVolume = function(amt) {
    $player.changeVolume(amt);
  }

  $scope.getPlayIcon = function() {
    return $scope.paused ? 'icon-play' : 'icon-pause';
  };
}

// controller for playlist tab
function PlaylistCtrl($scope, $http, $playlist) {
  // FIXME: is it better to use $emit and $handle instead of this?
  var $navScope = $('.albumList ul.nav').scope();
  $navScope.currentNav = 'playlist';

  // copy over playlist from playlist module
  $scope.playlist = $playlist.playlist;
}

// controller for left pane artist -> album list
function ArtistListCtrl($scope, $http) {
  $http.get('/artists/').success( function(data) {
    // transform what we receive from the server
    // array of objects, name is artist name, albums is list of strings
    $scope.artists = [];
    for ( var i in data ) {
      var o = { 'name': i, 'albums': data[i] };
      $scope.artists.push(o);
    }
  });
}

// controller for right pane containing a number of albums with tracks inside
function ArtistDetailCtrl($scope, $http, $routeParams, $playlist, $player) {

  // call in template to queue a song, song is the JSON model
  $scope.queueTrack = function( song ) {
    $playlist.queue( song );
    // FIXME: just play whatever we click on for now
    $player.play( song );
    return false;
  }

  // FIXME: is it better to use $emit and $handle instead of this?
  var $navScope = $('.albumList ul.nav').scope();
  $navScope.currentNav = 'browse';

  // if the url doesn't have /:artist/
  if ( !$routeParams.artist ) {
    return;
  }

  // generate a 'nice' url for the browse button
  var url = '/' + $routeParams.artist;
  if ( $routeParams.album ) url += '/'+ $routeParams.album;

  // FIXME: is it better to use $emit and $handle instead of this?
  var $navScope = $('.albumList ul.nav').scope();
  $navScope.url = url;

  // url the actual json call is made at
  url = '/browse' + url;

  $http.get(url).success( function(data) {
    $scope.albums = {};
    var len = data.length;
    // transform what we receive from the server
    // group by album, with an array of songs inside
    for ( var i = 0; i < len; i++ ) {
      var song = data[i];

      if ( !$scope.albums[ song.id3_album ] ) {
        $scope.albums[ song.id3_album ] = { 'name': song.id3_album, 'date': song.id3_date, 'art': song.id, 'tracks': [] };
      }
      $scope.albums[ song.id3_album ].tracks.push( song );
    }
  });
}