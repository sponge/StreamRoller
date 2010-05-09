~function() {
    
var mod = {};
mm.playlist = mod;

var playlist = [];
var curr = 0;

mod.init = function() {
  mm.signal.register('songChanged', mod.drawPlaylist);
  mm.signal.register('playlistChanged', mod.drawPlaylist);
}

mod.new = function(arr) {
  playlist = arr;
  curr = 0;
  mm.signal.send('playlistChanged');
}

mod.nextSong = function() {
  curr = Math.abs((curr + 1) % (playlist.length));
  mm.signal.send('playlistChanged');
  return playlist[curr];
};

mod.prevSong = function() {
  if (curr - 1 < 0) curr = playlist.length;
  curr = Math.abs((curr - 1) % (playlist.length));
  mm.signal.send('playlistChanged');
  return playlist[curr];
};

mod.skip = function(i) {
  curr = i;
  mm.player.currSong = playlist[i];
  mm.signal.send('playlistChanged');
  return playlist[i];
};

mod.drawPlaylist = function() {
  var playlist_div = $('#playlist .list').html('<table><tbody></tbody></table>');
  var tbody = playlist_div.find('table > tbody');
  for (var i=0; playlist[i]; i++) {
    var e = $('<tr>');
    e.attr('data-rowindex',i)
      .bind('click', mod.playlistSkip)
      .bind('contextmenu', mod.deleteSong);
    if (curr == i && mm.player.currSong.id == playlist[i].id) {
      e.addClass('selected');
    }
    e.append('<td class="handle">h</td><td>'+ playlist[i].file +'</td>')
     
    playlist_div.find('table').tableDnD({
      onDrop: mod.sortChange,
      dragHandle: 'handle'
    });
    tbody.append(e);
  };
  $(window).trigger('resize');
};

mod.playlistSkip = function(e) {
  var i = $(e.currentTarget).attr('data-rowindex');
  mm.player.load( mod.skip(i) );
};

mod.sortChange = function(table, row) {
  var rows = table.tBodies[0].rows;
  var newPlaylist = [];
  for (var i=0; rows[i]; i++) {
    var oldIndex = $(rows[i]).attr('data-rowindex');
    newPlaylist[i] = playlist[oldIndex];
  }
  mod.new(newPlaylist);
};

mod.addSong = function(o) {
  var len = playlist.length;
  if (typeof o == 'array') {
    playlist = playlist.concat(o);
  } else {
    playlist.push(o);
  }
  if (len == 0) {
    mm.player.load(mod.skip(0));
  }
  mm.signal.send('playlistChanged');
}

mod.deleteSong = function(e) {
  var i = $(e.currentTarget).attr('data-rowindex');
  if (i <= curr) {
    curr--;
  }
  playlist.splice(i, 1);
  mm.signal.send('playlistChanged');
  return false;
}

}();