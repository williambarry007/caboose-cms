
$(document).ready(function() {
  $('#caboose_login').colorbox({
    iframe: true,
    initialWidth: 400,
    initialHeight: 200,
    innerWidth: 400,
    innerHeight: 200,
    scrolling: false,
    transition: 'fade',
    closeButton: false,
    onComplete: fix_colorbox,
    opacity: 0.50
  });
  $('#caboose_register').colorbox({
    iframe: true,
    initialWidth: 400,
    initialHeight: 324,
    innerWidth: 400,
    innerHeight: 324,
    scrolling: false,
    transition: 'fade',
    closeButton: false,
    onComplete: fix_colorbox,
    opacity: 0.50
  });
  $.ajax({
    url: '/station/plugin-count',
    success: function (count) {      
      $('#caboose_station').colorbox({
        iframe: true,
        innerWidth: 200,
        innerHeight: count * 50,
        transition: 'fade',
        closeButton: false,
        onComplete: fix_colorbox,
        opacity: 0.50
      });
    }
  });
});

function fix_colorbox() {
  $("#cboxTopLeft"      ).css('background', '#111');
  $("#cboxTopRight"     ).css('background', '#111');
  $("#cboxBottomLeft"   ).css('background', '#111');
  $("#cboxBottomRight"  ).css('background', '#111');
  $("#cboxMiddleLeft"   ).css('background', '#111');
  $("#cboxMiddleRight"  ).css('background', '#111');
  $("#cboxTopCenter"    ).css('background', '#111');
  $("#cboxBottomCenter" ).css('background', '#111');
  $("#cboxClose"        ).hide();
  //$('#cboxLoadedContent').css('margin-bottom', 0);
  //h = $('#cboxLoadedContent').height();
  //$('#cboxLoadedContent').css('height', ''+(h+28)+'px'); 
}
