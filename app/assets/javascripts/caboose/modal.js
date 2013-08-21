// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require colorbox-rails

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
