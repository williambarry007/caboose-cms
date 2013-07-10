
$(document).ready(function() {
  $('#caboose_login'    ).colorbox({ iframe: true, initialWidth: 400, initialHeight: 200, innerWidth: 400, innerHeight: 200, scrolling: false, transition: 'fade', closeButton: false, onComplete: fix_colorbox, opacity: 0.50 });
  $('#caboose_register' ).colorbox({ iframe: true, initialWidth: 400, initialHeight: 324, innerWidth: 400, innerHeight: 324, scrolling: false, transition: 'fade', closeButton: false, onComplete: fix_colorbox, opacity: 0.50 });
  $('#caboose_station'  ).colorbox({ iframe: true, initialWidth: 200, initialHeight: 50,  innerWidth: 200, innerHeight:  50, scrolling: false, transition: 'fade', closeButton: false, onComplete: fix_colorbox, opacity: 0.50 });
});

function fix_colorbox() {
  var padding = 21; // 21 is default
  $("#cboxTopLeft"      ).css('background', '#111');
  $("#cboxTopRight"     ).css('background', '#111');
  $("#cboxBottomLeft"   ).css('background', '#111');
  $("#cboxBottomRight"  ).css('background', '#111');
  $("#cboxMiddleLeft"   ).css('background', '#111');
  $("#cboxMiddleRight"  ).css('background', '#111');
  $("#cboxTopCenter"    ).css('background', '#111');
  $("#cboxBottomCenter" ).css('background', '#111');
  $("#cboxClose"        ).hide();
  
  //var p = (padding-21)*2;
  //$("#cboxWrapper"      ).css('padding', '0 ' + p + ' ' + p + ' 0');
  //$('#cboxLoadedContent').css('margin-bottom', 0);
  //h = $('#cboxLoadedContent').height();
  //$('#cboxLoadedContent').css('height', ''+(h+28)+'px'); 
}

//lastkeys = "";
//$(document).keyup(function(e) {
//  if (e.keyCode == 13 && (lastkeys == "caboose" || lastkeys == "CABOOSE")) 
//    $.colorbox({ href: '/station', iframe: true, initialWidth: 200, initialHeight: 50,  innerWidth: 200, innerHeight:  50, scrolling: false, transition: 'fade', closeButton: false, onComplete: fix_colorbox, opacity: 0.50 });
//
//  lastkeys += String.fromCharCode(e.keyCode);  
//  if (lastkeys.length > 7)
//    lastkeys = lastkeys.substr(1);  
//});
