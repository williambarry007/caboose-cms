var ModalController = Class.extend({
    
  modal_width: false,
  modal_height: false,
  modal_element: false,  
  parent_controller: false,
  
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];
  },
  
  modal: function(el, width, height, callback)
  {
    var that = this;
    if (!width) width = that.modal_width ? that.modal_width : 400;
    if (!height) height = that.modal_height ? that.modal_height : $(el).outerHeight(true);
    that.modal_element = el;
    el.attr('id', 'the_modal');
    $("#caboose_sidebar_holder").html(el).addClass("visible").addClass("loading");
  },
  
  last_size: 0,
  autosize: function(msg, msg_container, flag)
  {    
    var that = this;
    if (msg) $('#' + (msg_container ? msg_container : 'modal_message')).html(msg);    
    $("#caboose_sidebar_holder").removeClass("loading");
  },
  
  before_close: false,
  close: function()
  {
    var that = this;
    if (that.before_close) that.before_close();
    $("#caboose_sidebar_holder").removeClass("visible");
    setTimeout(function(){ $("#caboose_sidebar_holder").html("") }, 500); 
  },

  /*****************************************************************************
  Asset management
  *****************************************************************************/
  
  // To be overridden in each controller
  assets_to_include: function() { return []; }, 
  
  // Called at the beginning of init to include modal assets,
  // and can be called at anytime with more assets
  include_assets: function(arr, after)
  {
    var that = this;    
    if (!arr) arr = that.assets_to_include();
    if (!arr) return;
                
    if (!that.parent_controller.included_assets || that.parent_controller.included_assets == undefined)
      that.parent_controller.included_assets = [];
    if (typeof arr == 'string') arr = [arr];
    $.each(arr, function(i, url) {      
      if (that.asset_included(url)) return;      
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
  
  asset_included: function(url)
  {
    var that = this;
    if (!that.parent_controller.included_assets || that.parent_controller.included_assets == undefined)
      that.parent_controller.included_assets = [];
    return that.parent_controller.included_assets.indexOf(url) > -1;    
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
