
var CabooseModal = function(w, h) {  
  if (!h)
  {
    $('#modal_content').css('width', w);
    h = $('#modal_content').outerHeight(true);
  }  
  if (parent.$.fn.colorbox)
    this.resize(w, h);
};

CabooseModal.prototype = {
  
  width: 0,
  height: 0, 
  set_width:  function(w) { this.width = w; this.colorbox(); },
  set_height: function(h) { this.height = h; this.colorbox(); },
  resize: function(w, h) { this.width = w; this.height = h; this.colorbox(); },
  
  // Resizes the height of the modal based on the content height
  autosize: function(msg, msg_container) {
    if (msg)      
      $('#' + (msg_container ? msg_container : 'message')).empty().append(msg);
    this.height = $('#modal_content').outerHeight(true);
    this.colorbox();
  },
  
  colorbox: function() {
    if (parent && parent.$.fn.colorbox)
    {
      parent.$.fn.colorbox.resize({ 
        innerWidth:  '' + this.width + 'px', 
        innerHeight: '' + this.height + 'px' 
      });
    }
  },
  
  close: function() {
    if (parent && parent.$.fn.colorbox)
      parent.$.fn.colorbox.close();      
  }
};

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
