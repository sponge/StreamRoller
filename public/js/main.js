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
    $(table).width( ($(table).width() > 450 ) ? $(table).width() : 450 );
    return table;
  };
  
  mm.clickRow = function(e) {
    var o = currData[this.getAttribute('data-rowindex')];
    if (!o) {
      window.location.hash = mm.utils.findParentDir(window.location.hash);
      return false;
    }
    
    if (o.folder == 't') {
      window.location.hash = o.path +'/'+ o.file;
      return false;
    }
    
    mm.playlist.addSong(o);
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
      
      songs = [];
      for (var i=0; data[i]; i++) {
        if (!data[i].folder) {
          songs.push(data[i]);
        }
      }
    }
    ajaxHandle = $.getJSON('/list/'+dir, showDirCallback);
  };
  
  mm.resize = function(e) {
    if ( $(window).width() < $('#listing').outerWidth(true) + $('#playlist').outerWidth(true) ) {
      $('#playlist').addClass('smallDisplay');
    } else {
      $('#playlist').removeClass('smallDisplay');
    }
  }
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
  
  $(window).resize(mm.resize);
});