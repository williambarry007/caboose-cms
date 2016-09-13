
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
  //caboose_modal('caboose_login');
  //caboose_modal('caboose_register');
  //caboose_modal('caboose_station');    
  $('a.caboose_modal').each(function(i, a) { caboose_modal_iframe($(a)); });  
});

function caboose_modal_iframe(el)
{
  var options = {
    iframe: true,
    initialWidth: 400, 
    initialHeight: 200, 
    innerWidth: 400, 
    innerHeight: 200, 
    scrolling: false, 
    transition: 'fade', 
    closeButton: false, 
    onComplete: caboose_fix_colorbox, 
    opacity: 0.50 
  };  
  if (typeof(el) == 'string')
    $('#'+el).colorbox(options);
  else
    el.colorbox(options);  
}

function caboose_modal(el)
{
  var options = {      
    initialWidth: 400, 
    initialHeight: 200, 
    innerWidth: 400, 
    innerHeight: 200, 
    scrolling: false, 
    transition: 'fade', 
    closeButton: false, 
    onComplete: caboose_fix_colorbox, 
    opacity: 0.50 
  };  
  if (typeof(el) == 'string')
    $('#'+el).colorbox(options);
  else
    el.colorbox(options);  
}

function caboose_modal_url(url)
{
  $.colorbox({
    href: url,
    iframe: true,
    innerWidth: 200,
    innerHeight:  50,
    scrolling: false,
    transition: 'fade',
    closeButton: false,
    onComplete: caboose_fix_colorbox,
    opacity: 0.50       
  });
}

var caboose_modal_close_handler = function(var1){};

function caboose_fix_colorbox() {
  var color = '#111';
  if (typeof COLORBOX_COLOR !== 'undefined')
    color = COLORBOX_COLOR;
  
  var padding = 21; // 21 is default
  $("#cboxTopLeft"      ).css('background', color);
  $("#cboxTopRight"     ).css('background', color);
  $("#cboxBottomLeft"   ).css('background', color);
  $("#cboxBottomRight"  ).css('background', color);
  $("#cboxMiddleLeft"   ).css('background', color);
  $("#cboxMiddleRight"  ).css('background', color);
  $("#cboxTopCenter"    ).css('background', color);
  $("#cboxBottomCenter" ).css('background', color);
  $("#cboxClose"        ).hide();    
}
