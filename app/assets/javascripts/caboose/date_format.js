Date.prototype.format = function(str_format, utc_offset) {
  var obj = new Date(this.getTime()+this.getTimezoneOffset()*60000+utc_offset*3600000);
  var two = function(s, pad) {
    if (pad == null) pad = '0';
    return s < 10 ? pad + s : s + ""; 
  };
  //return str_format.replace(/MM|yyyy|hh|mm|ss|ampm/g, function(pattern){
  //  switch(pattern){
  
  var month_name = function(i) {
    switch (i) {
      case 0  : return 'January';
      case 1  : return 'February';
      case 2  : return 'March';
      case 3  : return 'April';
      case 4  : return 'May';
      case 5  : return 'June';
      case 6  : return 'July';
      case 7  : return 'August';
      case 8  : return 'September';
      case 9  : return 'October';
      case 10 : return 'November';
      case 11 : return 'December';
    }
  };
  
  var twelve_hours = function(h) {
    if (h <= 12) return h;
    return h - 12;    
  };
           
  return str_format.replace(/%Y|%y|%m|%_m|%-m|%B|%b|%d|%-d|%e|%j|%H|%k|%I|%l|%P|%p|%M|%S/g, function(pattern) {
    switch(pattern) {
      case '%Y'  : return obj.getFullYear();                       // Year with century (can be negative, 4 digits at least)       
      case '%y'  : return obj.getFullYear() % 100;                 // Year without century
      case '%m'  : return two(obj.getMonth()+1);                   // Month of the year, zero-padded (01..12)      
      case '%-m' : return obj.getMonth()+1;                        // Month of the year, no-padded (1..12)
      case '%B'  : return month_name(obj.getMonth());              // The full month name (``January'')            
      case '%b'  : return month_name(obj.getMonth()).substr(0, 3); // The abbreviated month name (``Jan'')                
      case '%d'  : return two(obj.getDate());                      // Day of the month, zero-padded (01..31)
      case '%-d' : return obj.getDate();                           // Day of the month, no-padded (1..31)
      case '%e'  : return two(obj.getDate(), ' ');                 // Day of the month, blank-padded ( 1..31)      
      case '%H'  : return two(obj.getHours());                     // Hour of the day, 24-hour clock, zero-padded (00..23)
      case '%k'  : return two(obj.getHours(), ' ');                // Hour of the day, 24-hour clock, blank-padded ( 0..23)
      case '%I'  : return two(twelve_hours(obj.getHours()));       // Hour of the day, 12-hour clock, zero-padded (01..12)
      case '%l'  : return two(twelve_hours(obj.getHours()), ' ');  // Hour of the day, 12-hour clock, blank-padded ( 1..12)
      case '%P'  : return (obj.getHours() >= 12 ? 'pm' : 'am');    // Meridian indicator, lowercase (``am'' or ``pm'')
      case '%p'  : return (obj.getHours() >= 12 ? 'PM' : 'AM');    // Meridian indicator, uppercase (``AM'' or ``PM'')
      case '%M'  : return two(obj.getMinutes());                   // Minute of the hour (00..59)
      case '%S'  : return two(obj.getSeconds());                   // Second of the minute (00..59)          
    }
  });
};