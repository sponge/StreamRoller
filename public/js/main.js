~function() {
  window.mm = {};
  
  var ajaxHandle,
      currData = [],
      songCache = [];
  
  mm.pageHistory = function(e) {
    mm.showDir(e.path, '#listing');
  };
  
  mm.renderTable = function(data) {
    var listing = '';
    var lastSong = data[0];
    var group = [];
    for (var i=0; data[i]; i++) {
      if (data[i]['id3_album'] == lastSong['id3_album']) {
        group.push(data[i]);
        continue;
      } else {
        lastSong = data[i];
        listing += mm.renderGroup(group);
        group = [data[i]];
      }
    }
    
    if (group[0]) {
      listing += mm.renderGroup(data);
    }
    return listing;
  };

  mm.renderGroup = function(data) {
    var tbody = [];
    for (var i=0; data[i]; i++) {
        var f = data[i];
        var row = ['<tr data-songid="', f['id'] ,'"><td>', f['id3_track'] ,'</td> <td>', f['id3_title'] ,'</td> <td align="right">', mm.utils.formatTime(f['length']) ,'</td></tr>'].join('');
        tbody.push(row);
    }
    var grp = ['<div class="listingGroup">',
    ,'<div class="groupName">', data[0]['id3_artist'] ,' - ', data[0]['id3_album'] ,' [', data[0]['id3_date'] ,']</div>'
    ,'<div class="groupPhoto"><img src="/pic/', data[0].id ,'" width="96" height="96"/></div>'
    ,'<table class="groupContents">'
    ,'  <tbody>'
    , tbody.join('')
    ,'  </tbody>'
    ,'</table>'
    ,'</div>'].join('');

    return grp;
  }
  
  mm.clickRow = function(e) {
    var o = songCache[this.getAttribute('data-songid')];
    mm.playlist.addSong(o);
    return false;
  };

  mm.toggleRow = function(e) {
    $(this).parent('li').toggleClass('open');
    $(this).next('ul').slideToggle();
  }
  
  mm.showDir = function(dir, div) {
    dir = mm.utils.stripSlashes(dir);
    if (ajaxHandle) {
      ajaxHandle.abort();
    }

    function showDirCallback(data, textStatus) {
      if (!data) {
        alert('Failed');
        return;
      }

      var content = mm.renderTable(data);
      $(div).html(content);

      currData = data;

      songs = [];
      for (var i=0; data[i]; i++) {
        if (!data[i].folder) {
          songCache[data[i]['id']] = data[i];
          songs.push(data[i]);
        }
      }
      var title = (dir) ? ' ('+dir+')' : '';
      $('#browser .title').text('Browser'+ title);
      $(window).trigger('resize');
    }
    ajaxHandle = $.getJSON('/list/'+dir, showDirCallback);
  };
  
  mm.resize = function(e) {
    $('#folders .list').height($('#folders').height() - $('#folders .section_header').outerHeight());
    $('#listing').height($('#browser').height() - $('#browser .section_header').outerHeight());
  };
  
  mm.addFolder = function() {
    var newSongs = [];
    for (var i=0; currData[i]; i++) {
      if (!currData[i].folder) {
        newSongs.push(currData[i]);
      }
    }
    $('#playlist-settings').hide();
    mm.playlist.addSongs(newSongs);
  };
  
  mm.clearPlaylist = function() {
    $('#playlist-settings').hide();
    mm.playlist.newList();
  };
  
  mm.downloadM3U = function() {
    mm.playlist.generateM3U();
  };
}();

$(document).ready(function() {

  if (!window.console) {
    window.console = { log: function(){}, dir: function(){} };
  }

  $('#playlist .section_header .options').bind('click', function(e) {
    $('#playlist-settings').toggle()
      .position({
        my: 'left top',
        at: 'left top',
        of: e,
        offset: '10 10'
      });
      return false;
  });
  
  $('#playlist-settings ul li').bind('click', function(e) {
    var func = $(e.currentTarget).attr('data-func');
    mm[func]();
  });

  $('body').disableSelection();

  $.address.change(mm.pageHistory);
  

  window.setTimeout(function() {
  $.getJSON('/dirs', function(data) {
    var recurse = function(d, pathStr) {
      var $str = $('<ul/>');
      for (var i in d) {
        var p2 = pathStr+'/'+i;
        var $li = $("<li/>");
        var $a = $('<a href="'+ p2 +'"><div class="status"></div>'+ i +'</a>');

        $li.append($a);
        $str.append($li);
        var sub = recurse(d[i], p2);
        if (sub.children().length) {
          $li.append(sub);
        }
      }
      return $str;
    }

    var list = recurse(data, '#');
    $('#folders .list').html( list );
    $('#folders .list ul li:has(ul)').addClass('sub');
  });
  },500);

  $(window).bind('resize', mm.resize);
  $(window).trigger('resize');

  $('#browser').delegate('.groupContents tbody tr', 'click', mm.clickRow);
  $('#folders .list').delegate('a', 'click', mm.toggleRow);

  
  mm.player.init();
  mm.settings.init();
  mm.playlist.init();
  
});
