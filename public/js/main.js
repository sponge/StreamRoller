~function() {
  window.mm = {};
  
  var defaultCols = ['id3_track', 'id3_title', 'id3_album', 'id3_artist' ],
      defaultLabels = ['#', 'Title', 'Album', 'Artist'],
      ajaxHandle,
      currData;
  
  mm.pageHistory = function(e) {
    mm.showDir(e.path, '#listing');
  };
  
  mm.renderTable = function(dir, data, columns, headers) {
    currData = data;
    var table = $(mm.tmpl('tmpl_mediatable', {data: data, columns: columns, headers: headers, parent: mm.utils.findParentDir(dir) }));
    $(table).find('tbody tr').bind('click', mm.clickRow);
    return table;
  };
  
  mm.clickRow = function(e) {
    var o = currData[this.getAttribute('rel')];
    if (!o) {
      window.location.hash = mm.utils.findParentDir(window.location.hash);
      return false;
    }
    
    if (o.folder == 't') {
      window.location.hash = o.path +'/'+ o.file;
      return false;
    }
    
    mm.player.play(o);
    return false;
  };
  
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
      var content = mm.renderTable(dir, data, defaultCols, defaultLabels);
      $(div).html(content);
      
    }
    ajaxHandle = $.getJSON('/list/'+dir, showDirCallback);
  };
}();

~function() {
  var mod = {};
  mm.utils = mod;
  
  mod.stripSlashes = function(str) {
    // strip off trailing/leading slashes
    return str.replace(/^\/|\/$/g,'');
  };
  
  mm.utils.generateLink = function(rel, href, label) {
    return ['<a rel="', rel, '" href="', href, '">', label, '</a>'].join('');
  };
  
  mod.findParentDir = function(path) {
    path = mm.utils.stripSlashes(path);
    var parts = path.split('/');
    parts.pop();
    var dir = (parts.length === 0) ? '/' : parts.join('/');
    return dir;
  };
  
  mod.formatTime = function(time) {
      time /= 1000;
      return Math.floor(time/60) +':'+ ((time%60 < 10) ? '0' : '')+ Math.floor(time%60);
  };
}();

~function() {
  var mod = {};
  mm.player = mod;
  
  var global_lp = 0;
  var playerHnd, muteLvl;

  function showPlayBtn() {
    $("#pause").hide();
    $("#play").show();
  }
  
  function showPauseBtn() {
    $("#pause").show();
    $("#play").hide();
  }
  
  mod.init = function() {
    playerHnd = $("#jquery_jplayer");
    
    $("#pause").hide();
    playerHnd.jPlayer({
      customCssIds: true,
      swfPath: "/"
    })
    .jPlayer("onProgressChange", function(lp,ppr,ppa,pt,tt) {
      var lpInt = parseInt(lp, 10);
      var ppaInt = parseInt(ppa, 10);
      global_lp = lpInt;
  
      $('#loaderBar').progressbar('option', 'value', lpInt);
      $('#sliderPlayback').slider('option', 'value', ppaInt);
    })
    .jPlayer("onSoundComplete", function() {
      // goto next playlist entry
    });
    
    $("#volume-min").click(mm.player.toggleMute);
  
    $("#player_progress_ctrl_bar a").live( "click", function() {
      playerHnd.jPlayer("playHead", this.id.substring(3)*(100.0/global_lp));
      return false;
    });
  
    $('#play').button({ text: false, disabled: true, icons: {primary:'ui-icon-play'}}).click(mm.player.play);
    $('#pause').button({ text: false, disabled: true, icons: {primary:'ui-icon-pause'}}).click(mm.player.pause);
    $('#stop').button({ text: false, disabled: true, icons: {primary:'ui-icon-stop'}}).click(mm.player.stop);
    $('#mute').button({ text: false, icons: {primary:'ui-icon-volume-on'}}).click(mm.player.toggleMute);
  
    // Slider
    $('#sliderPlayback').slider({
      max: 100,
      range: 'min',
      slide: function(event, ui) {
        playerHnd.jPlayer("playHead", ui.value*(100.0/global_lp));
      }
    });
  
    $('#sliderVolume').slider({
      value : 80,
      max: 100,
      range: 'min',
      slide: function(event, ui) {
        mm.player.setVol(ui.value, false);
      }
    });
  
    $('#loaderBar').progressbar();
  };
  
  mod.play = function() {
    var o = arguments[0];
    if (o.id) {
      playerHnd.jPlayer('setFile', '/get/'+o.id);
      mod.setInfo(o);
    }
    
    playerHnd.jPlayer("play");
    $('#play, #pause, #stop').button('option', 'disabled', false );
    
    showPauseBtn();
    return false;
  };
  
  mod.setInfo = function(o) {
    var str = '<b>Now Playing:</b> '+
      ((o.id3_title) ? o.id3_title : o.file) +
      ((o.id3_artist) ? ' by '+ o.id3_artist : '') +
      ((o.id3_album) ? ' from the album '+ o.id3_album : '');
    $('#nowplaying').html(str);
  };
  
  mod.pause = function() {
    playerHnd.jPlayer("pause");
    showPlayBtn();
    return false;
  };
  
  mod.stop = function() {
      playerHnd.jPlayer("stop");
      showPlayBtn();
      return false;
  };
  
  mod.setVol = function(vol, updateSlider) {
    playerHnd.jPlayer("volume", vol);
    if (!updateSlider) $('#sliderVolume').slider('option', 'value', vol);   
  };
  
  mod.toggleMute = function() {
    if (muteLvl) {
      $('#mute').button('option', 'icons', {primary:'ui-icon-volume-on'});
      mm.player.setVol(muteLvl);
      muteLvl = 0;
    } else {
      $('#mute').button('option', 'icons', {primary:'ui-icon-volume-off'});
      muteLvl = playerHnd.jPlayer('getData','volume');
      mm.player.setVol(0);
    }
    return false;    
  };
}();

// Simple JavaScript Templating
// John Resig - http://ejohn.org/ - MIT Licensed
var cache = {};
mm.tmpl = function tmpl(str, data) {
    // Figure out if we're getting a template, or if we need to
    // load the template - and be sure to cache the result.
    var fn = !/\W/.test(str) ?
  cache[str] = cache[str] ||
    tmpl(document.getElementById(str).innerHTML) :

    // Generate a reusable function that will serve as a template
    // generator (and which will be cached).
  new Function("obj",
    "var p=[],print=function(){p.push.apply(p,arguments);};" +

    // Introduce the data as local variables using with(){}
    "with(obj){p.push('" +

    // Convert the template into pure JavaScript
    str.replace(/[\r\t\n]/g, " ")
       .replace(/'(?=[^%]*%>)/g,"\t")
       .split("'").join("\\'")
       .split("\t").join("'")
       .replace(/<%=(.+?)%>/g, "',$1,'")
       .split("<%").join("');")
       .split("%>").join("p.push('")
       + "');}return p.join('');");

    // Provide some basic currying to the user
    return data ? fn(data) : fn;
};

$(document).ready(function() {

  if (!window.console) {
    window.console = { log: function(){}, dir: function(){} };
  }
  
  mm.player.init();
  
  $('#listing')
    .ajaxStart(function() { $(this).hide(); } )
    .ajaxStop(function() { $(this).show(); } );

  $.address.change(mm.pageHistory);
});