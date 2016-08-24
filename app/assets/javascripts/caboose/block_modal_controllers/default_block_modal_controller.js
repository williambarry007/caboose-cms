
var DefaultBlockModalController = ModalController.extend({

  page_id: false,
  block_id: false,
  block: false,
  block_types: false,
  authenticity_token: false,
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
    var that = this;
    that.refresh_block(function() {
      if (callback) callback();
    });                  
  },
  
  refresh_block: function(callback)
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
  
  print_content: function() {},
  
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
        { name: 'block_type_id' , nice_name: 'Block type' , type: 'select'   , value: b.block_type.id         , text: b.block_type.name              , width: 400, fixed_placeholder: true, options_url: '/admin/block-types/options'                      , after_update: function() { that.parent_controller.render_blocks(); that.block.block_type.id = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }},
        { name: 'parent_id'     , nice_name: 'Parent ID'  , type: 'select'   , value: b.parent_id             , text: b.parent ? b.parent.title : '' , width: 400, fixed_placeholder: true, options_url: '/admin/pages/' + that.page_id + '/block-options' , after_update: function() { that.parent_controller.render_blocks(); that.block.parent_id     = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }},
        { name: 'constrain'     , nice_name: 'Constrain'  , type: 'checkbox' , value: b.constrain     ? 1 : 0 ,                                        width: 400, fixed_placeholder: true,                                                                  after_update: function() { that.parent_controller.render_blocks(); that.block.constrain     = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }},
        { name: 'full_width'    , nice_name: 'Full Width' , type: 'checkbox' , value: b.full_width    ? 1 : 0 ,                                        width: 400, fixed_placeholder: true,                                                                  after_update: function() { that.parent_controller.render_blocks(); that.block.full_width    = this.value; }, after_cancel: function() { that.parent_controller.render_blocks(); }, on_load: function() { that.modal.autosize(); }}
      ]
    });
    that.autosize();
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

});
