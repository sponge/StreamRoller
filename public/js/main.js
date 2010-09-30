/*
	reflection.js for jQuery v1.03
	(c) 2006-2009 Christophe Beyls <http://www.digitalia.be>
	MIT-style license.
*/
(function(a){a.fn.extend({reflect:function(b){b=a.extend({height:1/3,opacity:0.5},b);return this.unreflect().each(function(){var c=this;if(/^img$/i.test(c.tagName)){function d(){var g=c.width,f=c.height,l,i,m,h,k;i=Math.floor((b.height>1)?Math.min(f,b.height):f*b.height);if(a.browser.msie){l=a("<img />").attr("src",c.src).css({width:g,height:f,marginBottom:i-f,filter:"flipv progid:DXImageTransform.Microsoft.Alpha(opacity="+(b.opacity*100)+", style=1, finishOpacity=0, startx=0, starty=0, finishx=0, finishy="+(i/f*100)+")"})[0]}else{l=a("<canvas />")[0];if(!l.getContext){return}h=l.getContext("2d");try{a(l).attr({width:g,height:i});h.save();h.translate(0,f-1);h.scale(1,-1);h.drawImage(c,0,0,g,f);h.restore();h.globalCompositeOperation="destination-out";k=h.createLinearGradient(0,0,0,i);k.addColorStop(0,"rgba(255, 255, 255, "+(1-b.opacity)+")");k.addColorStop(1,"rgba(255, 255, 255, 1.0)");h.fillStyle=k;h.rect(0,0,g,i);h.fill()}catch(j){return}}a(l).css({display:"block",border:0});m=a(/^a$/i.test(c.parentNode.tagName)?"<span />":"<div />").insertAfter(c).append([c,l])[0];m.className=c.className;a.data(c,"reflected",m.style.cssText=c.style.cssText);a(m).css({width:g,height:f+i,overflow:"hidden"});c.style.cssText="display: block; border: 0px";c.className="reflected"}if(c.complete){d()}else{a(c).load(d)}}})},unreflect:function(){return this.unbind("load").each(function(){var c=this,b=a.data(this,"reflected"),d;if(b!==undefined){d=c.parentNode;c.className=d.className;c.style.cssText=b;a.removeData(c,"reflected");d.parentNode.replaceChild(c,d)}})}})})(jQuery);

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
      listing += mm.renderGroup(group);
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
    ,'<table class="groupContents" cellspacing="0">'
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
    $(this).next('ul').slideToggle(100);
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
      $(div).find('.groupPhoto img').reflect();
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

  $('#playlist .section_header').toggle(function(e) {
    $(this).next().attr('style', 'height:500px;');
  },
  function(e) {
    $(this).next().removeAttr('style');
  });

  
  mm.player.init();
  mm.settings.init();
  mm.playlist.init();
  
});
