
var BlockModalController = DefaultBlockModalController.extend({
  
  block_types: false,    
  
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
        var complex_field_types = ['block', 'richtext', 'image', 'file'];
        $.each(that.block.children, function(i, b) {
          var div_id = 'block_' + b.id + (complex_field_types.indexOf(b.block_type.field_type) == -1 ? '_value' : '');
          div.append($('<div/>').css('margin-bottom', '10px').append($('<div/>').attr('id', div_id)));                                
        });
      }              
      else
      {
        div.append($('<p/>').append("This block doesn't have any content yet."));
      }
      if (that.block.block_type.allow_child_blocks)
      {
        div.append($('<p/>').css('clear', 'both').append($('<a/>').attr('href', '#').html("Add a child block!").click(function(e) {
          e.preventDefault();
          that.add_block();
        })));            
      }
    }
    $('#modal_content').replaceWith(div);
    that.render_blocks();    
    that.set_editable();
    that.autosize();
  },
    
  /*****************************************************************************
  Block Rendering
  *****************************************************************************/

  render_blocks: function()
  {
    var that = this;    
    if (that.block.block_type.field_type != 'block' && that.block.children.length == 0)
      return;
    
    $.each(that.block.children, function(i, b) {      
      var ft = b.block_type.field_type;      
      if (ft == 'block' || ft == 'richtext' || ft == 'image' || ft == 'file')
      {
        if (!b.rendered_value)
        {
          $.ajax({
            block_id: b.id, // Used in the success function
            url: that.block_url(b) + '/render',
            type: 'get',
            success: function(html) {
              $('#the_modal #block_' + this.block_id).replaceWith(html);
              
              var b2 = that.block_with_id(this.block_id);
              b2.rendered_value = html;
              that.set_clickable(b2);                            
              that.autosize();
            },            
          });
        }
        else
          $('#the_modal #block_' + b.id).replaceWith(b.rendered_value);
      }
    });        
  },
  
  /****************************************************************************/
  
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
    //if (b.allow_child_blocks == true)
    //{
    //  $('#new_block_' + b.id).replaceWith($('<input/>')
    //    .attr('type', 'button')
    //    .val('New Block')
    //    .click(function(e) { e.stopPropagation(); that.new_block(b.id);          
    //    })
    //  );
    //} 
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

  /****************************************************************************/

  set_editable: function()
  {
    var that = this;
    that.set_block_value_editable(that.block);        
    $.each(that.block.children, function(i, b) {
      that.set_block_value_editable(b);                         
    });        
  },
  
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
  
  /****************************************************************************/

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
    var h = {                      
      authenticity_token: that.authenticity_token,
      block_type_id: block_type_id
    };
    if (that.before_id ) h['before_id'] = that.before_id;
    if (that.after_id  ) h['after_id' ] = that.after_id;

    $.ajax({
      url: '/admin/' + (that.page_id ? 'pages/' + that.page_id : 'posts/' + that.post_id) + '/blocks/' + that.block_id,
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

});
