~function() {
    
var mod = {};
mm.playlist = mod;

mod.playlist = [];
mod.curr = 0;

mod.new = function(arr) {
  mod.playlist = arr;
  mod.curr = 0;
  mm.signal.send('playlistChanged');
}

mod.nextSong = function() {
  mod.curr = Math.abs((mod.curr + 1) % (mod.playlist.length));
  mm.signal.send('playlistChanged');
  return mod.playlist[mod.curr];
};

mod.prevSong = function() {
  if (mod.curr - 1 < 0) mod.curr = mod.playlist.length;
  mod.curr = Math.abs((mod.curr - 1) % (mod.playlist.length));
  mm.signal.send('playlistChanged');
  return mod.playlist[mod.curr];
};

mod.skip = function(i) {
  mod.curr = i;
  mm.player.currSong = mod.playlist[i];
  mm.signal.send('playlistChanged');
  return mod.playlist[i];
};

mod.drawPlaylist = function() {
  var playlist_div = $('#playlist .list').html('<table><tbody></tbody></table>');
  var tbody = playlist_div.find('table > tbody');
  for (var i=0; mod.playlist[i]; i++) {
    var e = $('<tr>');
    e.attr('data-rowindex',i)
      .bind('click', mod.playlistSkip)
      .bind('contextmenu', mod.deleteSong);
    if (mod.curr == i && mm.player.currSong.id == mod.playlist[i].id) {
      e.addClass('selected');
    }
    e.append('<td class="handle">h</td><td>'+ mod.playlist[i].file +'</td>')
     
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
    newPlaylist[i] = mod.playlist[oldIndex];
  }
  mod.new(newPlaylist);
};

mod.addSong = function(o) {
  mod.playlist.push(o);
  var len = mod.playlist.length;
  if (len == 1) {
    mm.player.load(mod.skip(len-1));
  }
  mm.signal.send('playlistChanged');
}

mod.deleteSong = function(e) {
  var i = $(e.currentTarget).attr('data-rowindex');
  mod.playlist.splice(i, 1);
  mm.signal.send('playlistChanged');
  return false;
}

mm.signal.register('songChanged', mod.drawPlaylist);
mm.signal.register('playlistChanged', mod.drawPlaylist);

}();