
var ModalController = Class.extend({
    
  modal_width: false,
  modal_height: false,
  modal_element: false,  
  parent_controller: false,

  modal: function(el, width, height, callback)
  {
    var that = this;
    if (!width) width = that.modal_width ? that.modal_width : 400;
    if (!height) height = that.modal_height ? that.modal_height : $(el).outerHeight(true);
    that.modal_element = el;    
    el.attr('id', 'the_modal').addClass('modal').css('width', '' + width + 'px');      
    $.colorbox({
      html: el,           
      initialWidth: width, 
      //initialHeight: height, 
      innerWidth: width, 
      //innerHeight: height, 
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
  
  last_size: 0,
  autosize: function(msg, msg_container, flag)
  {    
    var that = this;
    if (!flag)
      that.last_size = 0;
    if (!that.modal_element) return;
    if (msg) $('#' + (msg_container ? msg_container : 'modal_message')).html(msg);    
    var h = that.modal_height ? that.modal_height : $(that.modal_element).outerHeight(true) + 20;    
    if (h > 0 && h > that.last_size)    
      $.colorbox.resize({ innerHeight: '' + h + 'px' });
    that.last_size = h;
    
    if (!flag || flag < 2)
      setTimeout(function() { that.autosize(false, false, flag ? flag + 1 : 1); }, 200);
  },
  
  before_close: false,
  close: function()
  {
    var that = this;
    if (that.before_close) that.before_close();
    $.colorbox.close();    
  },

  /*****************************************************************************
  Asset management
  *****************************************************************************/
  
  // To be overridden in each controller
  assets_to_include: function() { return []; }, 
  
  // Called at the beginning of init to include modal assets,
  // and can be called at anytime with more assets
  include_assets: function(arr)
  {
    var that = this;    
    if (!arr) arr = that.assets_to_include();
    if (!arr) return;
                
    if (!that.parent_controller.included_assets || that.parent_controller.included_assets == undefined)
      that.parent_controller.included_assets = [];
    if (typeof arr == 'string') arr = [arr];
    $.each(arr, function(i, url) {        
      if (that.parent_controller.included_assets.indexOf(url) > -1) return;
      var full_url = url.match(/^http:.*?/) || url.match(/^https:.*?$/) || url.match(/^\/\/.*?$/) ? url : that.assets_path + url;        
      if (url.match(/\.js/))
      {
        var el = document.createElement('script');    
        el.setAttribute('type', 'text/javascript');                  
        el.setAttribute('src', full_url);        
        document.getElementsByTagName('head')[0].appendChild(el)
      }
      else if (url.match(/\.css/))
      {
        var el = document.createElement('link');
        el.setAttribute('rel', 'stylesheet');
        el.setAttribute('type', 'text/css');
        el.setAttribute('href', full_url);
        document.getElementsByTagName('head')[0].appendChild(el)
      }
      that.parent_controller.included_assets.push(url);
    });
  },
  
  include_inline_css: function(str)  
  {
    var that = this;
    
    if (!that.parent_controller.included_css || that.parent_controller.included_css == undefined)
      that.parent_controller.included_css = [];
    var h = that.hashify(str);
    if (that.parent_controller.included_css.indexOf(h) > -1)
      return;
    
    var el = document.createElement('style');    
    el.setAttribute('type', 'text/css');
    el.innerHTML = str;
    document.getElementsByTagName('head')[0].appendChild(el)
    
    that.parent_controller.included_css.push(h);
  },
  
  hashify: function(str)
  {    
    var hash = 0, i, chr, len;
    if (str.length === 0) return hash;
    for (i=0, len=str.length; i<len; i++) {
      chr   = str.charCodeAt(i);
      hash  = ((hash << 5) - hash) + chr;
      hash |= 0; // Convert to 32bit integer
    }
    return hash;    
  }
  
});
