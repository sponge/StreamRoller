~function() {

var mod = {};
window.groupBrowser = mod;

mod.draw = function(data, dest) {

  var listing = '';
  var lastSong = data[0];
  var group = [];
  for (var i=0; data[i]; i++) {
    if (data[i]['id3_album'] == lastSong['id3_album']) {
      group.push(data[i]);
      continue;
    } else {
      lastSong = data[i];
      listing += mod.renderGroup(group);
      group = [data[i]];
    }
  }
  
  if (group[0]) {
    listing += mod.renderGroup(group);
  }

  $(dest).html(listing);
  $(dest).find('.groupPhoto img').reflect();

};

mod.renderGroup = function(data) {
  var tbody = [];
  for (var i=0; data[i]; i++) {
      var f = data[i];
      var row = ['<tr data-songid="', f['id'] ,'"><td>', f['id3_track'] ,'</td> <td>', f['id3_title'] ,'</td> <td align="right">', mm.utils.formatTime(f['length']) ,'</td></tr>'].join('');
      tbody.push(row);
  }
  var grp = ['<div class="listingGroup">',
  ,'<div class="groupName">', data[0]['id3_artist'] ,' - ', data[0]['id3_album'] ,' [', data[0]['id3_date'] ,']</div>'
  ,'<div class="groupPhoto"><img src="/pic/', data[0].id ,'" width="96" height="96"/></div>'
  ,'<table class="groupContents" cellspacing="0">'
  ,'  <tbody>'
  , tbody.join('')
  ,'  </tbody>'
  ,'</table>'
  ,'</div>'].join('');

  return grp;
};

}();
