~function() {

var mod = {};
mm.delegates['artistDataSource'] = mod;

var ajaxHandle,
    songCache = []
    currData = [];

mod.getData = function(dir, callback) {
  if (ajaxHandle) {
   ajaxHandle.abort();
  }

  ajaxHandle = $.ajax({
    url: mm.settings.get('baseURL') +'/browse/'+ dir,
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
  $.getJSON('/artists', function(data) {
    var $html = $('<div>');
    var $str = $('<ul/>');
    $html.append($str);

    for (var artist in data) {
      var path = '/'+artist;
      var $li = $("<li/>");
      var $a = $('<a href="#'+ path +'"><div class="status"></div>'+ artist +'</a>');
      $li.append($a);

      var albums = data[artist];
      var $ul2 = $('<ul>');
      for (var i in albums) {
        var path2 = path+'/'+albums[i];
        var $li2 = $("<li/>");
        var $a2 = $('<a href="#'+ path2 +'">'+ albums[i] +'</a>');
        $li2.append($a2);
        $ul2.append($li2);
      }
      $li.append($ul2);
      $str.append($li);
    }

    var container = $('<div class="list"></div>');
    container.html( $html.html() );
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
