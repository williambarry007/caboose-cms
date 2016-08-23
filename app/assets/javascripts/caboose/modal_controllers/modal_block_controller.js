
var ModalBlockController = ModalController.extend({

  block_types: false,
    
  after_refresh: function()
  {
    var that = this;
    that.update_on_close = false;
    $.each(that.block.children, function(i, b) {
      if (b.block_type.field_type == 'image' || b.block_type.field_type == 'file')
        that.update_on_close = true; 
    });    
    that.print();        
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
      that.refresh(function() { that.after_refresh() });
      return;
    }
    
    var div = $('<div/>').attr('id', 'modal_content');      
    if (that.block.block_type.field_type != 'block')
      div.append($('<p/>').append($('<div/>').attr('id', 'block_' + that.block.id + '_value')));
    else
    {
      if (that.block.children.length > 0)
      {        
        $.each(that.block.children, function(i, b) {          
          if (b.block_type.field_type != 'block' && b.block_type.field_type != 'richtext' && b.block_type.field_type != 'image' && b.block_type.field_type != 'file')        
            div.append($('<div/>').css('margin-bottom', '10px').append($('<div/>').attr('id', 'block_' + b.id + '_value')));
          else
          {
            div.append($('<div/>').css('margin-bottom', '10px').append($('<div/>').attr('id', 'block_' + b.id)));            
          }
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
    $('#modal_crumbtrail').empty().append(that.crumbtrail());
    $('#modal_controls').empty().append(that.controls());

    that.render_blocks();    
    that.set_editable();
    that.autosize();    
  },
  
  controls: function()
  {
    var that = this;
    var p = $('<p/>').css('clear', 'both')
      .append($('<input/>').attr('type', 'button').addClass('btn').val('Close').click(function() { that.close(); if (that.update_on_close) { that.parent_controller.render_blocks(); } })).append(' ');
    if (!that.block.name)                        
      p.append($('<input/>').attr('type', 'button').addClass('btn').val('Delete Block').click(function() { that.delete_block(); })).append(' ');      
    p.append($('<input/>').attr('type', 'button').addClass('btn').val('Move Up'   ).click(function() { that.move_up();         })).append(' ');
    p.append($('<input/>').attr('type', 'button').addClass('btn').val('Move Down' ).click(function() { that.move_down();       })).append(' ');
    p.append($('<input/>').attr('type', 'button').addClass('btn').val('Advanced'  ).attr('id', 'btn_advanced').click(function() { that.print_advanced();  }));
    return p;
  },
  
  print_advanced: function()
  {
    var that = this;
    var b = that.block;
    
    $('#modal_content').empty()      
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + b.id + '_block_type_id' )))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + b.id + '_parent_id'     )))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + b.id + '_constrain'     )))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + b.id + '_full_width'    )))      
    $('#modal_controls').empty()
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').addClass('btn').val('Close').click(function() { that.close(); if (that.update_on_close) { that.parent_controller.render_blocks(); } })).append(' ')                              
        .append($('<input/>').attr('type', 'button').addClass('btn').val('Back' ).click(function() { that.print(); }))
      );
              
    var m = new ModelBinder({
      name: 'Block',
      id: b.id,
      update_url: that.block_url(b),      
      authenticity_token: that.authenticity_token,
      attributes: [
        { name: 'block_type_id' , nice_name: 'Block type' , type: 'select'   , value: b.block_type_id         , text: b.block_type.name              , width: 400, fixed_placeholder: true, options_url: '/admin/block-types/options'                      , after_update: function() { that.parent_controller.render_blocks(); that.block.block_type_id = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }},
        { name: 'parent_id'     , nice_name: 'Parent ID'  , type: 'select'   , value: b.parent_id             , text: b.parent ? b.parent.title : '' , width: 400, fixed_placeholder: true, options_url: '/admin/pages/' + that.page_id + '/block-options' , after_update: function() { that.parent_controller.render_blocks(); that.block.parent_id     = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }},
        { name: 'constrain'     , nice_name: 'Constrain'  , type: 'checkbox' , value: b.constrain     ? 1 : 0 ,                                        width: 400, fixed_placeholder: true,                                                                  after_update: function() { that.parent_controller.render_blocks(); that.block.constrain     = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }},
        { name: 'full_width'    , nice_name: 'Full Width' , type: 'checkbox' , value: b.full_width    ? 1 : 0 ,                                        width: 400, fixed_placeholder: true,                                                                  after_update: function() { that.parent_controller.render_blocks(); that.block.full_width    = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }}
      ]
    });
    that.autosize();
  },
  
  crumbtrail: function()
  {    
    var that = this;
    var crumbs = $('<h2/>').css('margin-top', '0').css('padding-top', '0');
    $.each(that.block.crumbtrail, function(i, h) {
      if (i > 0) crumbs.append(' > ');
      crumbs.append($('<a/>').attr('href', '#').html(h['text']).data('block_id', h['block_id']).click(function(e) { 
        e.preventDefault();
        that.parent_controller.edit_block(parseInt($(this).data('block_id')));
      }));
    });    
    return crumbs;
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
        if (b2.block_type_id = 34)
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

  delete_block: function(confirm)
  {
    var that = this;
    if (!confirm)
    {
      var p = $('<p/>').addClass('note warning')
        .append("Are you sure you want to delete the block? This can't be undone.<br />")      
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.delete_block(true); })).append(' ')
        .append($('<input/>').attr('type','button').val('No').click(function() { $('#modal_message').empty(); that.autosize(); }));
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
  }

});
