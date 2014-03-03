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
		self.loggedIn = window.loggedIn || false;
		
		$('a[href="/register"], [caboose=register]').click(function(event) {
			event.preventDefault();
			self.register( $(window).width() < 1024 );
		});
		
		$('a[href="/login"], [caboose=login]').click(function(event) {
			event.preventDefault();
			self.login( $(window).width() < 1024 );
		});
		
		$('a[href="/logout"], [caboose=logout]').click(function(event) {
			event.preventDefault();
			self.logout( $(window).width() < 1024 );
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
	
	self.login = function(mobile) {
		if (mobile) window.location.href = '/login?return_url=' + window.location.pathname;
		
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
		if (mobile) window.location.href = '/register?return_url=' + window.location.pathname;
		
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
