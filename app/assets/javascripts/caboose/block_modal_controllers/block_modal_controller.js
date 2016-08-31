
var BlockModalController = ModalController.extend({
  
  page_id: false,
  post_id: false,
  block_id: false,
  block: false,
  block_types: false,
  authenticity_token: false,
  new_block_on_init: false,
  assets_path: false,
  block_types: false,
  complex_field_types: ['block', 'richtext', 'image', 'file'],
    
  init: function(params) 
  {    
    var that = this;    
    for (var i in params)
      that[i] = params[i];    
    that.include_assets();
    if (that.new_block_on_init == true)
      that.refresh_block(function() { that.add_block(); });
    else
      that.print();    
  },
  
  refresh: function(callback)
  {    
    var that = this;
    that.refresh_block(function() {
      if (callback) callback();
    });                  
  },
  
  refresh_block: function(callback)
  {    
    var that = this;
    $.ajax({
      url: that.block_url() + '/tree',
      type: 'get',
      success: function(arr) {
        that.block = arr[0];        
        if (callback) callback();
      }        
    });
  },

  /*****************************************************************************
  Printing
  *****************************************************************************/
  
  print: function()
  {    
    var that = this;    
    if (!that.block)
    {          
      var div = $('<div/>')
        .append($('<div/>').attr('id', 'modal_crumbtrail' ))
        .append($('<div/>').attr('id', 'modal_content'    ))
        .append($('<div/>').attr('id', 'modal_message'    ))
        .append($('<div/>').attr('id', 'modal_controls'   ));
      that.modal(div, 800);
      that.refresh(function() { that.print(); });      
      return;
    }
    
    that.print_content();
    that.print_crumbtrail();
    that.print_controls();    
    that.autosize();    
  },
  
  add_child_link_text: false,
  child_block_header_text: false,  
  
  print_content: function()
  {
    var that = this;
    var div = $('<div/>').attr('id', 'modal_content');      
    if (that.block.block_type.field_type != 'block')
      div.append($('<p/>').append($('<div/>').attr('id', 'block_' + that.block.id + '_value')));
    else
    {
      if (that.block.children.length > 0)
      {        
        var separate_children = that.block.block_type.allow_child_blocks && that.block.block_type.default_child_block_type_id;
        var separate_child_id = separate_children ? that.block.block_type.default_child_block_type_id : false;
    
        $.each(that.block.children, function(i, b) {
          if (separate_children && b.block_type.id == separate_child_id) return;                    
          var div_id = 'block_' + b.id + (that.complex_field_types.indexOf(b.block_type.field_type) == -1 ? '_value' : '');
          div.append($('<div/>').css('margin-bottom', '10px').append($('<div/>').attr('id', div_id)));                                
        });
        if (separate_children)
        {
          if (that.child_block_header_text) div.append($('<h2/>').append(that.child_block_header_text));                    
          $.each(that.block.children, function(i, b) {
            if (b.block_type.id == separate_child_id)
            {
              var div_id = 'block_' + b.id + (that.complex_field_types.indexOf(b.block_type.field_type) == -1 ? '_value' : '');
              div.append($('<div/>').css('margin-bottom', '10px').append($('<div/>').attr('id', div_id)));
            }             
          });
        }    
      }              
      else
      {
        div.append($('<p/>').append("This block doesn't have any content yet."));
      }
      if (that.block.block_type.allow_child_blocks)
      {        
        div.append($('<p/>').css('clear', 'both').append($('<a/>').attr('href', '#').html(that.add_child_link_text ? that.add_child_link_text : "Add a child block!").click(function(e) {
          e.preventDefault();
          that.add_block();
        })));                            
      }
    }
    $('#modal_content').replaceWith(div);
    that.render_child_blocks();
    that.autosize();
  },
  
  print_controls: function()
  {    
    var that = this;
    var p = $('<p/>').css('clear', 'both')
      .append($('<input/>').attr('type', 'button').addClass('btn').val('Close').click(function() { that.close(); that.parent_controller.render_blocks(); })).append(' ');
    if (!that.block.name)                        
    {
      p.append($('<input/>').attr('type', 'button').addClass('btn').val('Delete Block').click(function() { that.delete_block(); })).append(' '); 
    }
    p.append($('<input/>').attr('type', 'button').addClass('btn').val('Move Up'   ).click(function() { that.move_up();         })).append(' ');
    p.append($('<input/>').attr('type', 'button').addClass('btn').val('Move Down' ).click(function() { that.move_down();       })).append(' ');    
    p.append($('<input/>').attr('type', 'button').addClass('btn').val('Advanced'  ).attr('id', 'btn_advanced').click(function() { that.print_advanced();  }));
    $('#modal_controls').empty().append(p);    
  },
  
  before_crumbtrail_click: false,
  print_crumbtrail: function()
  {    
    var that = this;
    var crumbs = $('<h2/>').css('margin-top', '0').css('padding-top', '0');
    $.each(that.block.crumbtrail, function(i, h) {
      if (i > 0) crumbs.append(' > ');
      crumbs.append($('<a/>').attr('href', '#').html(h['text']).data('block_id', h['block_id']).click(function(e) { 
        e.preventDefault();
        if (that.before_crumbtrail_click) that.before_crumbtrail_click();
        that.parent_controller.edit_block(parseInt($(this).data('block_id')));
      }));
    }); 
    $('#modal_crumbtrail').empty().append(crumbs);        
  },
  
  before_print_advanced: false,
  print_advanced: function()
  {
    var that = this;        
    if (that.before_print_advanced) that.before_print_advanced();
    
    var b = that.block;    
    $('#modal_content').empty()      
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + b.id + '_block_type_id' )))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + b.id + '_parent_id'     )))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + b.id + '_constrain'     )))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + b.id + '_full_width'    )))      
    $('#modal_controls').empty()
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').addClass('btn').val('Close').click(function() { 
          that.close();
          that.parent_controller.render_blocks(); 
        })).append(' ')                              
        .append($('<input/>').attr('type', 'button').addClass('btn').val('Back' ).click(function() { 
          that.print_content();
          that.print_controls();          
        }))
      );
              
    var m = new ModelBinder({
      name: 'Block',
      id: b.id,
      update_url: that.block_url(b),      
      authenticity_token: that.authenticity_token,
      attributes: [
        { name: 'block_type_id' , nice_name: 'Block type' , type: 'select'   , value: b.block_type.id         , text: b.block_type.name              , width: 400, fixed_placeholder: true, after_update: function() { that.parent_controller.render_blocks(); that.block.block_type.id = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }, options_url: '/admin/block-types/options' },
        { name: 'parent_id'     , nice_name: 'Parent ID'  , type: 'select'   , value: b.parent_id             , text: b.parent ? b.parent.title : '' , width: 400, fixed_placeholder: true, after_update: function() { that.parent_controller.render_blocks(); that.block.parent_id     = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }, options_url: '/admin/' + (that.page_id ? 'pages/' + that.page_id : 'posts/' + that.post_id) + '/block-options' },
        { name: 'constrain'     , nice_name: 'Constrain'  , type: 'checkbox' , value: b.constrain     ? 1 : 0 ,                                        width: 400, fixed_placeholder: true, after_update: function() { that.parent_controller.render_blocks(); that.block.constrain     = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }},
        { name: 'full_width'    , nice_name: 'Full Width' , type: 'checkbox' , value: b.full_width    ? 1 : 0 ,                                        width: 400, fixed_placeholder: true, after_update: function() { that.parent_controller.render_blocks(); that.block.full_width    = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }}
      ]
    });
    that.autosize();
  },
  
  /*****************************************************************************
  Block Rendering
  *****************************************************************************/

  render_child_blocks: function()
  {
    var that = this;    
    if (that.block.block_type.field_type != 'block' && that.block.children.length == 0)
      return;
    
    $.each(that.block.children, function(i, b) { that.render_child_block(b); });        
  },
  
  render_child_block: function(b)
  {
    var that = this;    
    if (that.complex_field_types.indexOf(b.block_type.field_type) > -1)
    {
      if (!b.rendered_value)
      {
        $.ajax({          
          url: that.block_url(b) + '/render',
          type: 'get',
          success: function(html) {
            $('#the_modal #block_' + b.id).replaceWith(html);
            
            var b2 = that.block_with_id(b.id);            
            b2.rendered_value = html;
            that.set_clickable(b2);                            
            that.autosize();
          },            
        });
      }
      else
        $('#the_modal #block_' + b.id).replaceWith(b.rendered_value);
    }
    else
      that.set_block_value_editable(b);
  },
  
  /****************************************************************************/

  //set_editable: function()
  //{
  //  var that = this;
  //  that.set_block_value_editable(that.block);        
  //  $.each(that.block.children, function(i, b) {
  //    that.set_block_value_editable(b);                         
  //  });        
  //},
  
  set_block_value_editable: function(b)
  {    
    var that = this;    
    var bt = b.block_type;                      
    if (bt.field_type == 'block' || bt.field_type == 'richtext')        
      return;      
    var h = {
      name: 'value',
      type: bt.field_type,      
      nice_name: bt.description ? bt.description : bt.name,
      width: bt.width ? bt.width : 780,      
      after_update: function() { that.parent_controller.render_blocks(); },
      after_cancel: function() { that.parent_controller.render_blocks(); }
    };     
    h['value'] = b.value
    if (bt.field_type == 'checkbox')       h['value'] = b.value ? 'true' : 'false';
    //if (bt.field_type == 'image')          h['value'] = b.image.tiny_url;
    //if (bt.field_type == 'file')           h['value'] = b.file.url;                
    if (bt.field_type == 'select')         h['text'] = b.value;
    if (bt.height)                         h['height'] = bt.height;
    if (bt.fixed_placeholder)              h['fixed_placeholder'] = bt.fixed_placeholder;      
    if (bt.options || bt.options_function) h['options_url'] = '/admin/block-types/' + bt.id + '/options';
    else if (bt.options_url)               h['options_url'] = bt.options_url;
    if (bt.field_type == 'file')           h['update_url'] = that.block_url(b) + '/file';
    if (bt.field_type == 'image')
    {
      h['update_url'] = that.block_url(b) + '/image'
      h['image_refresh_delay'] = 100;
    }
        
    m = new ModelBinder({
      name: 'Block',
      id: b.id,
      update_url: that.block_url(b),
      authenticity_token: that.authenticity_token,
      attributes: [h]            
    });
  },
  
  set_clickable: function(b)
  {        
    var that = this;
        
    if (!b)
    {
      $.each(that.block.children, function(i,b) {
        that.set_clickable(b);                      
      });
    }

    $('#the_modal #block_' + b.id).attr('onclick','').unbind('click');    
    $('#the_modal #block_' + b.id).click(function(e) {      
      e.stopPropagation();
      that.parent_controller.edit_block(b.id); 
    });     
    var show_mouseover = true;
    if (b.children && b.children.length > 0)
    {
      $.each(b.children, function(i, b2) {
        if (b2.block_type.id = 34)
          show_mouseover = false;
        that.set_clickable(b2);
      });
    }    
    if (show_mouseover)
    {
      $('#the_modal #block_' + b.id).mouseover(function(el) { $('#the_modal #block_' + b.id).addClass(   'block_over'); });
      $('#the_modal #block_' + b.id).mouseout(function(el)  { $('#the_modal #block_' + b.id).removeClass('block_over'); }); 
    }    
  },

  /*****************************************************************************
  CRUD
  *****************************************************************************/

  add_block: function(block_type_id)
  {
    var that = this;
         	       
	  that.include_inline_css(
	    "@font-face {\n" +
	    "  font-family: 'icomoon';\n" + 
      "  src: url('" + that.assets_path + "icomoon.eot?-tne7s4');\n" +
      "  src: url('" + that.assets_path + "icomoon.eot?#iefix-tne7s4') format('embedded-opentype'),\n" +
		  "       url('" + that.assets_path + "icomoon.woff?-tne7s4') format('woff'),\n" +
		  "       url('" + that.assets_path + "icomoon.ttf?-tne7s4') format('truetype'),\n" +
		  "       url('" + that.assets_path + "icomoon.svg?-tne7s4#icomoon') format('svg');\n" +
		  "  font-weight: normal;\n" +
		  "  font-style: normal;\n" +
	    "}\n"
	  );
    that.include_assets([
      'caboose/icomoon_fonts.css',
      'caboose/admin_new_block.css'
    ]);
    
    if (!block_type_id && that.block.block_type.default_child_block_type_id)
    {
      that.add_block(that.block.block_type.default_child_block_type_id);
      return;
    }      
    else if (!block_type_id)
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
      that.modal(div, 780);
      return;
    }    
    that.autosize("<p class='loading'>Adding block...</p>");
    
    bt = false;
    $.ajax({      
      url: '/admin/block-types/' + block_type_id + '/json',
      type: 'get',      
      success: function(resp) { bt = resp; },
      async: false      
    });
    if (bt.use_js_for_modal)    
      that.include_assets('caboose/block_modal_controllers/' + bt.name + '_modal_controller.js');
    
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
        if (resp.success)
        {                    
          that.parent_controller.refresh_blocks(function() {
            that.parent_controller.edit_block(resp.new_id);
            that.parent_controller.render_blocks();            
          });
        }
      }
    });        
  },

  delete_block: function(confirm)
  {
    var that = this;
    if (!confirm)
    {
      var p = $('<p/>').addClass('note warning')
        .append("Are you sure you want to delete the block? This can't be undone.<br />")      
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.delete_block(true); })).append(' ')
        .append($('<input/>').attr('type','button').val('No').click(function() { $('#modal_message').empty(); that.autosize(); 
        }));
      that.autosize(p);
      return;
    }
    that.autosize("<p class='loading'>Deleting block...</p>");
    $.ajax({
      url: that.block_url(that.block),
      type: 'delete',    
      success: function(resp) {
        if (resp.error) that.autosize("<p class='note error'>" + resp.error + "</p>");
        if (resp.redirect) 
        {
          that.close();
          that.parent_controller.render_blocks();          
        }
      }
    });
  },
    
  move_up: function()
  {
    var that = this;
    that.autosize("<p class='loading'>Moving up...</p>");
    $.ajax({
      url: that.block_url(that.block) + '/move-up',
      type: 'put',    
      success: function(resp) {
        if (resp.error) that.autosize("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) 
        {
          that.autosize("<p class='note success'>" + resp.success + "</p>");          
          that.parent_controller.render_blocks();
        }
      }
    });    
  },
  
  move_down: function()
  {
    var that = this;
    that.autosize("<p class='loading'>Moving down...</p>");
    $.ajax({
      url: that.block_url(that.block) + '/move-down',
      type: 'put',    
      success: function(resp) {
        if (resp.error) that.autosize("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) 
        {
          that.autosize("<p class='note success'>" + resp.success + "</p>");          
          that.parent_controller.render_blocks();
        }
      }
    });    
  },
  
  /*****************************************************************************
  Helper methods
  *****************************************************************************/
  
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
    if (!b)
      return '/admin/' + (that.page_id && that.page_id != null ? 'pages/' + that.page_id : 'posts/' + that.post_id) + '/blocks';            
    return '/admin/' + (b.page_id && b.page_id != null ? 'pages/' + b.page_id : 'posts/' + b.post_id) + '/blocks';        
  },
  
  block_url: function(b)
  {
    var that = this;    
    if (!b) return that.base_url() + '/' + that.block_id;    
    return that.base_url(b) + '/' + b.id;          
  },
  
  child_block: function(name, b)
  {
    var that = this;
    if (!b) b = that.block;
    var the_block = false;
    $.each(b.children, function(i, b2) {
      if (b2.name == name)
      {
        the_block = b2;
        return false;
      }
    });
    return the_block;
  },
  
  child_block_value: function(name, b)
  {
    var that = this;
    var b2 = that.child_block(name, b);
    if (!b2) return false;
    return b2.value;
  },

});

$(document).trigger('block_modal_controller_loaded');
