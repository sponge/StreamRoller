(function () {

   
var mm = {};

window.mm = mm;

mm.defaultCols = ['id3_track', 'id3_title', 'id3_album', 'id3_artist' ];
mm.defaultLabels = ['#', 'Title', 'Album', 'Artist'];
mm.ajaxHandle = undefined;

mm.pageHistory = function(e) {
  mm.showDir(e.path, '#listing');
};

mm.utils = {};

mm.utils.stripSlashes = function(str) {
  // strip off trailing/leading slashes
  return str.replace(/^\/|\/$/g,'')
};

mm.utils.generateLink = function(rel, href, label) {
  return ['<a rel="', rel, '" href="', href, '">', label, '</a>'].join('');
}

mm.utils.findParentDir = function(path) {
  path = mm.utils.stripSlashes(path);
  var parts = path.split('/');
  parts.pop();
  var dir = parts.length == 0 ? '/' : parts.join('/');
  return dir;
};

mm.utils.formatTime = function(time) {
    time /= 1000;
    return Math.floor(time/60) +':'+ ((time%60 < 10) ? '0' : '')+ Math.floor(time%60);
};

mm.player = {};

mm.player.play = function(url) {
    document.MediaStreamer.playURL(url);
};

mm.player.playPause = function() {
    document.MediaStreamer.playPause();
};

mm.player.getDownloadInfo = function() {
    return document.MediaStreamer.getDownloadInfo();
};

mm.player.recvDownloadInfo = function(o) {
    var time = mm.utils.formatTime(o.length);
    var percent = Math.floor(o.bytesLoaded / o.bytesTotal * 100);
    percent = (percent != 100) ? ' ('+percent+'%)' : '';
    $('#song-time').text(time + percent);
};

mm.player.recvTime = function(time) {
    $('#song-progress').text(mm.utils.formatTime(time));
};

mm.player.playEvent = function(e) {
    console.log(e);
    try {
        mm.player.play(e.target.href);
    } catch (e) {
        console.log(e);
    } finally {
        return false;
    }
};

mm.showDir = function(dir, div) {
  dir = mm.utils.stripSlashes(dir);
  if (mm.ajaxHandle) {
    mm.ajaxHandle.abort();
  }
  mm.ajaxHandle = $.getJSON('/list/'+dir, showDirCallback);
  function showDirCallback(data, textStatus) {
    if (!data) {
      alert('Failed');
      return;
    }
    content = mm.renderTable(dir, data, mm.defaultCols, mm.defaultLabels);
    $(div).html(content);
    var links = $(div).find('a[rel="media"]').bind('click', mm.player.playEvent);
  };
};

mm.renderTable = function(dir, data, columns, headers) {
  return mm.tmpl('tmpl_mediatable', {data: data, columns: columns, headers: headers, parent: mm.utils.findParentDir(dir) });
};

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
    window.console = { log: function(){}, dir: function(){} }
  }
  
  $.address.change(mm.pageHistory);
  $('#status')
    .ajaxStart(function() { $(this).html('<font color="red">Loading...</font>') } )
    .ajaxStop(function() { $(this).html('<font color="green">Loaded</font>') } );
});


}());