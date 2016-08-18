
var ModalController = Class.extend({
  
  page_id: false,
  block_id: false,
  block: false,
  modal_element: false,
  authenticity_token: false,
    
  init: function(params) {
    var that = this;
    for (var i in params)
      that[i] = params[i];
    that.print();    
  },
  
  refresh: function(callback)
  {
    var that = this
    $.ajax({
      url: '/admin/pages/' + that.page_id + '/blocks/' + that.block_id + '/tree',
      type: 'get',
      success: function(arr) {
        that.block = arr[0];
        if (callback) callback();
      }        
    });
  },

  modal: function(el, width, height, callback)
  {
    var that = this;
    if (!width) width = 400;
    if (!height) height = $(el).outerHeight(true);
    that.modal_element = el;    
    el.attr('id', 'the_modal').addClass('modal').css('width', '' + width + 'px');      
    $.colorbox({
      html: el,           
      initialWidth: width, 
      initialHeight: height, 
      innerWidth: width, 
      innerHeight: height, 
      scrolling: false,        
      closeButton: false,
      opacity: 0.50,
      onComplete: function() {        
        var arr = ['TopLeft','TopCenter','TopRight','BottomLeft','BottomCenter','BottomRight','MiddleLeft','MiddleRight'];
        for (var i in arr) $('#cbox' + arr[i]).css('background-color', '#fff !important');        
        $("#cboxClose").hide();
        if (callback) callback();        
      }       
    });
  },
  
  autosize: function(msg, msg_container)
  {
    var that = this;    
    if (!that.modal_element) return;
    if (msg) $('#' + (msg_container ? msg_container : 'modal_message')).html(msg);
    var h = $(that.modal_element).outerHeight(true) + 20;    
    $.colorbox.resize({ innerHeight: '' + h + 'px' });
  },
  
  close: function()
  {
    $.colorbox.close();    
  }
  
});
