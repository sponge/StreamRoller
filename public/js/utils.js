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
  return (dir == '/') ? '' : dir;
};

mod.formatTime = function(time) {
    return Math.floor(time/60) +':'+ ((time%60 < 10) ? '0' : '')+ Math.floor(time%60);
};
  
}();