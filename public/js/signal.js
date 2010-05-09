~function () {
  
var mod = {};
mm.signal = mod;

var signals = [];

mod.register = function (s,f) {
  console.log("Registered signal: "+ s);
  if (!signals[s]) {
    signals[s] = [];
  }
  signals[s].push(f);
};

mod.send = function(s, data) {
  console.log("Sending signal: "+ s);
  if (signals[s] && signals[s].length > 0) {
    var len = signals[s].length;
    
    var o = $.extend({}, data);
    o.type = s;
    
    for (var i=0; i<len; i++) {
      signals[s][i].apply(undefined, [o]);
    }
  }
  
  return len;
};

mod.remove = function(s,f) {
  
};

}();