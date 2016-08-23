
var ModalController = Class.extend({
  
  page_id: false,
  block_id: false,
  block: false,
  modal_element: false,
  authenticity_token: false,
  parent_controller: false,
  new_block_on_init: false,
  assets_path: false,  
    
  init: function(params) 
  {
    var that = this;    
    for (var i in params)
      that[i] = params[i];    
    that.include_assets();
    if (that.new_block_on_init == true)
      that.add_block();
    else
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
    var h = $(that.modal_element).outerHeight(true) + 20;    
    if (h > 0 && h > that.last_size)    
      $.colorbox.resize({ innerHeight: '' + h + 'px' });
    that.last_size = h;
    
    if (!flag || flag < 2)
      setTimeout(function() { that.autosize(false, false, flag ? flag + 1 : 1); }, 200);
  },
  
  close: function()
  {
    $.colorbox.close();    
  },
  
  block_with_id: function(block_id, b)
  {
    var that = this;
    if (!b) b = that.block;
    if (b.id == block_id) return b;
    
    var the_block = false;
    $.each(b.children, function(i, b2) {
      the_block = that.block_with_id(block_id, b2);
      if (the_block)
        return false;
    });
    return the_block;        
  },
  
  base_url: function(b)
  {
    var that = this;
    if (!b) b = that.block; 
    return '/admin/' + (b.page_id ? 'pages/' + b.page_id : 'posts/' + b.post_id) + '/blocks';        
  },
  
  block_url: function(b)
  {
    var that = this;
    if (!b) b = that.block;
    return this.base_url(b) + '/' + b.id;          
  },
  
  add_block: function(block_type_id)
  {
    var that = this;
    
    that.include_assets([          
      'caboose/icomoon_fonts.css',
      'caboose/admin_new_block.css'
    ]);
    
    if (!that.block_type_id)
    {
      that.new_block_types = false;
      $.ajax({
        url: '/admin/block-types/new-options',
        type: 'get',
        success: function(resp) { that.new_block_types = resp; },
        async: false          
      });
      
      var icons = $('<div/>').addClass('icons');
      $.each(that.new_block_types, function(i, h) {        
        if (h.block_types && h.block_types.length > 0)
        {
          var cat = h.block_type_category;          
          icons.append($('<h2/>').click(function(e) { $('#cat_' + cat.id + '_container').slideToggle(); }).append(cat.name));
          var cat_container = $('<div/>').attr('id', 'cat_' + cat.id + '_container');
          $.each(h.block_types, function(j, bt) {            
            cat_container.append($('<a/>').attr('href', '#')
              .data('block_type_id', bt.id)
              .click(function(e) { e.preventDefault(); that.add_block($(this).data('block_type_id')); })
              .append($('<span/>').addClass('icon icon-' + bt.icon))
              .append($('<span/>').addClass('name').append(bt.description))
            );
          });
          icons.append(cat_container);
        }
      });
          
      var div = $('<div/>').append($('<form/>').attr('id', 'new_block_form')
        .submit(function(e) { e.preventDefault(); return false; })
        .append(icons)
      );
      that.modal(div, 800);
      return;
    }
    
    that.autosize("<p class='loading'>Adding block...</p>");    
    var h = {                      
      authenticity_token: that.authenticity_token,
      block_type_id: block_type_id
    };
    if (that.before_id ) h['before_id'] = that.before_id;
    if (that.after_id  ) h['after_id' ] = that.after_id;

    $.ajax({
      url: that.block_url(),
      type: 'post',
      data: h,
      success: function(resp) {
        if (resp.error)   that.autosize("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) that.parent_controller.edit_block(resp.new_id);        
      }
    });     
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
      if (url.match(/\.js/))
      {
        var el = document.createElement('script');    
        el.setAttribute('type', 'text/javascript');
        el.setAttribute('src', that.assets_path + url);
        document.getElementsByTagName('head')[0].appendChild(el)
      }
      else if (url.match(/\.css/))
      {
        var el = document.createElement('link');
        el.setAttribute('rel', 'stylesheet');
        el.setAttribute('type', 'text/css');
        el.setAttribute('href', that.assets_path + url);
        document.getElementsByTagName('head')[0].appendChild(el)
      }
      that.parent_controller.included_assets.push(url);
    });
  }  
});
