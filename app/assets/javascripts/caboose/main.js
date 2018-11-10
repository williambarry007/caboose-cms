//
// Caboose
//

var Caboose = function() {
	var self = this;
	
	//
	// Initialize
	//
	
	self.initialize = function() {
		self.loggedIn = window.loggedIn || false;
		
		// $('a[href="/register"], [caboose=register]').click(function(event) {
		// 	event.preventDefault();
		// 	self.register( $(window).width() < 1024 );
		// });
		
		// $('a[href="/login"], [caboose=login]').click(function(event) {
		// 	event.preventDefault();
		// 	self.login( $(window).width() < 1024 );
		// });
		
		// $('a[href="/logout"], [caboose=logout]').click(function(event) {
		// 	event.preventDefault();
		// 	self.logout( $(window).width() < 1024 );
		// });
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
	// Redirect
	//
	
	self.redirect = function(url) {
		if (!$.browser.mobile) {
			window.location.href = url;
		} else if ( (navigator.userAgent.match(/iPhone/i)) || (navigator.userAgent.match(/iPod/i)) ) {
			location.replace(url);
		} else if ($.browser.mobile) {
			document.location = url;
		}
	};
	
	//
	// Reload
	//
	
	self.reload = function() {
		self.redirect(window.location.href);
	};
	
	//
	// Login
	//
	
	self.login = function() {
		window.location = '/login?return_url=' + window.location.pathname;
		// if ($.browser.mobile) window.location.href = '/login?return_url=' + window.location.pathname;
		
		// $.colorbox({
		// 	href: '/login?return_url=' + window.location.pathname,
		// 	iframe: true,
		// 	innerWidth: 200,
		// 	innerHeight: 50,
		// 	scrolling: false,
		// 	transition: 'fade',
		// 	closeButton: false,
		// 	opacity: 0.50
		// });
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
		window.location = '/register?return_url=' + window.location.pathname;
		
		// $.colorbox({
		// 	href: '/register?return_url=' + window.location.pathname,
		// 	iframe: true,
		// 	innerWidth: 200,
		// 	innerHeight: 50,
		// 	scrolling: false,
		// 	transition: 'fade',
		// 	closeButton: false,
		// 	opacity: 0.50
		// });
	};
	
	// Init and return
	$(document).ready(self.initialize);
	return self;
};

// There can only be one
var Caboose = new Caboose();

//
// Caboose Store
//

Caboose.Store = (function(caboose) {
  var self = {
    Modules: {}
  };
  
  self.initialize = function() {
    _.each(self.Modules, function(module) {
      if (module.initialize) module.initialize();
    });
  };
  
  $(document).ready(self.initialize);
  return self;
}).call(Caboose);

//
// Delay
//

var delay = (function() {
  var timer = 0;
  
  return function(callback, ms) {
    clearTimeout(timer);
    timer = setTimeout(callback, ms);
  };
})();

//
// States
//

window.States = {
  "AL": "Alabama",
  "AK": "Alaska",
  "AS": "American Samoa",
  "AZ": "Arizona",
  "AR": "Arkansas",
  "CA": "California",
  "CO": "Colorado",
  "CT": "Connecticut",
  "DE": "Delaware",
  "DC": "District Of Columbia",
  "FM": "Federated States Of Micronesia",
  "FL": "Florida",
  "GA": "Georgia",
  "GU": "Guam",
  "HI": "Hawaii",
  "ID": "Idaho",
  "IL": "Illinois",
  "IN": "Indiana",
  "IA": "Iowa",
  "KS": "Kansas",
  "KY": "Kentucky",
  "LA": "Louisiana",
  "ME": "Maine",
  "MH": "Marshall Islands",
  "MD": "Maryland",
  "MA": "Massachusetts",
  "MI": "Michigan",
  "MN": "Minnesota",
  "MS": "Mississippi",
  "MO": "Missouri",
  "MT": "Montana",
  "NE": "Nebraska",
  "NV": "Nevada",
  "NH": "New Hampshire",
  "NJ": "New Jersey",
  "NM": "New Mexico",
  "NY": "New York",
  "NC": "North Carolina",
  "ND": "North Dakota",
  "MP": "Northern Mariana Islands",
  "OH": "Ohio",
  "OK": "Oklahoma",
  "OR": "Oregon",
  "PW": "Palau",
  "PA": "Pennsylvania",
  "PR": "Puerto Rico",
  "RI": "Rhode Island",
  "SC": "South Carolina",
  "SD": "South Dakota",
  "TN": "Tennessee",
  "TX": "Texas",
  "UT": "Utah",
  "VT": "Vermont",
  "VI": "Virgin Islands",
  "VA": "Virginia",
  "WA": "Washington",
  "WV": "West Virginia",
  "WI": "Wisconsin",
  "WY": "Wyoming"
};

function curr(x)
{
  if (!x) return '0.00'
  var t = typeof x;
  if (t == 'boolean') return '0.00';
  if (t == 'number')  return x.toFixed(2);
  if (t == 'string')  return parseFloat(x).toFixed(2);
  console.log("curr doesn't know what this is:");
  console.log(x);
  console.log(t);
  return 'STAHP'
}

function capitalize_first_letter(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}