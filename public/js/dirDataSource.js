~function() {

var mod = {};
mm.delegates['dirDataSource'] = mod;

var ajaxHandle,
    songCache = []
    currData = [];

mod.getData = function(dir, callback) {
  if (ajaxHandle) {
   ajaxHandle.abort();
  }

  ajaxHandle = $.ajax({
    url: mm.settings.get('baseURL') +'/list/'+ dir,
    dataType: 'json',
    success: showDirCallback,
  });

  function showDirCallback(data, textStatus) {
    if (!data) {
      alert('Failed');
      return;
    }

    currData = data;

    for (var i=0; data[i]; i++) {
      if (!data[i].folder) {
        songCache[data[i]['id']] = data[i];
      }
    }
    var title = dir ? ' ('+dir+')' : '';
    $('#browser .title').text('Browser'+ title);
    $(window).trigger('resize');

    callback(data);
  }

};

mod.getFolderView = function(dest) {
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
    var container = $('<div class="list"></div>');
    container.html( list );
    container.find('ul li:has(ul)').addClass('sub');
    $(dest).html(container);
  });
  },500);
};

mod.rowClicked = function(e) {
  $(this).parent('li').toggleClass('open');
  $(this).next('ul').slideToggle(100);
};

mod.getActiveSongs = function() {
  return currData;
};

mod.getSongById = function(id) {
  return songCache[id];
}

}();
