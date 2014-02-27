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
		$('a[href="/register"], [caboose=register]').click(function(event) {
			event.preventDefault();
			self.register();
		});
		
		$('a[href="/login"], [caboose=login]').click(function(event) {
			event.preventDefault();
			self.login();
		});
		
		$('a[href="/logout"], [caboose=logout]').click(function(event) {
			event.preventDefault();
			self.logout();
		});
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
	
	//
	// Login
	//
	
	self.login = function() {
		$.colorbox({
			href: '/login?return_url=' + window.location.pathname,
			iframe: true,
			innerWidth: 200,
			innerHeight: 50,
			scrolling: false,
			transition: 'fade',
			closeButton: false,
			opacity: 0.50
		});
	};
	
	//
	// Logout
	//
	
	self.logout = function() {
		window.location = '/logout';
	};
	
	//
	// Register
	//
	
	self.register = function(callback) {
		$.colorbox({
			href: '/register?return_url=' + window.location.pathname,
			iframe: true,
			innerWidth: 200,
			innerHeight: 50,
			scrolling: false,
			transition: 'fade',
			closeButton: false,
			opacity: 0.50
		});
	};
	
	// Init and return
	$(document).ready(self.initialize);
	return self;
};

// There can only be one
var Caboose = new Caboose();
