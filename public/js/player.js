~function() {
    
var mod = {};
mm.player = mod;

var global_lp = 0;
var playerHnd, muteLvl;
var paused = true;

mod.currSong = {};

function showPlayBtn() {
  $('#play').button('option', 'icons', {primary:'ui-icon-play'});
  paused = true;
}

function showPauseBtn() {
  $('#play').button('option', 'icons', {primary:'ui-icon-pause'});
  paused = false;
}

mod.init = function() {
  playerHnd = $("#jquery_jplayer");
  
  showPauseBtn();
  playerHnd.jPlayer({
    customCssIds: true,
    swfPath: "/"
  })
  .jPlayer("onProgressChange", function(lp,ppr,ppa,pt,tt) {
    var lpInt = parseInt(lp, 10);
    var ppaInt = parseInt(ppa, 10);
    global_lp = lpInt;

    $('#loaderBar').progressbar('option', 'value', lpInt % 100);
    $('#sliderPlayback').slider('option', 'value', ppaInt);
    
    $('#time').text(mm.utils.formatTime(pt/1000) +' / '+ mm.utils.formatTime(tt/1000));
  })
  .jPlayer("onSoundComplete", function() {
    mm.player.load(mm.playlist.nextSong());
  });
  
  $("#volume-min").click(mm.player.toggleMute);

  $("#player_progress_ctrl_bar a").live( "click", function() {
    playerHnd.jPlayer("playHead", this.id.substring(3)*(100.0/global_lp));
    return false;
  });

  $('#play').button({ text: false, disabled: true, icons: {primary:'ui-icon-play'}}).click(mm.player.togglePlay);
  $('#mute').button({ text: false, icons: {primary:'ui-icon-volume-on'}}).click(mm.player.toggleMute);
  $('#prev').button({ text: false, icons: {primary:'ui-icon-seek-prev'}}).click(mm.player.prevSong);
  $('#next').button({ text: false, icons: {primary:'ui-icon-seek-next'}}).click(mm.player.nextSong);

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

mod.load = function(o, autoplay) {
  autoplay = (autoplay == undefined) ? true : false;
  playerHnd.jPlayer('setFile', '/get/'+o.id);
  mod.setInfo(o);
  
  if (autoplay) {
    mod.play();
  }
}

mod.setInfo = function(o) {
  var str = '<strong>Now Playing:</strong> '+
    ((o.id3_title) ? o.id3_title : o.file) +
    ((o.id3_artist) ? ' <em>by</em> '+ o.id3_artist : '');
  $('#nowplaying').html(str);
  if (o.art) {
    $('#art img').attr('src', '/pic/'+o.id).show();
  } else {
    $('#art img').attr('src', '').hide();
  }
  mod.currSong = o;
  mm.signal.send('songChanged')
};

mod.play = function() {   
  playerHnd.jPlayer("play");
  $('#play').button('option', 'disabled', false );
  showPauseBtn();
  return false;
};

mod.pause = function() {
  playerHnd.jPlayer("pause");
  showPlayBtn();
  return false;
};

mod.togglePlay = function() {
  if (paused) {
    mod.play();
  } else {
    mod.pause();
  }
  
  return false;
}

mod.prevSong = function() {
  mod.load(mm.playlist.prevSong());
};

mod.nextSong = function() {
  mod.load(mm.playlist.nextSong());
  
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