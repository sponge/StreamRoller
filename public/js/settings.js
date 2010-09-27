~function() {
    
var mod = {};
mm.settings = mod;

mod.init = function() {
};

mod.show = function() {
  $('#settings').dialog({
		resizable: false,
    width: 450,
		height: 140,
		modal: true,
    draggable: false,
    title: 'StreamRoller Settings',
		buttons: {
      OK: function() {
				$(this).dialog('close');
			},
			Cancel: function() {
				$(this).dialog('close');
			}
		}
	});
};

}();