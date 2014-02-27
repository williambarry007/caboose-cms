//
// Main
//
// :: Initialize
// :: Events

var Caboose = function() {
	var self = this;
	
	//
	// Initialize
	//
	
	self.initialize = function() {
		//..
	};
	
	//
	// Events
	//
	
	self.events = {};
	
	self.events.trigger = function(event) {
		$(Caboose.events).trigger(event);
	};
	
	self.events.on = function(event, callback) {
		$(Caboose.events).on(event, callback);
	};
	
	// Init and return
	$(document).ready(self.initialize);
	return self;
};

// There can only be one
var Caboose = new Caboose();
