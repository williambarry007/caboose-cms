
var BlockController = function(options) { this.init(options) };

BlockController.prototype = {

  block: false,  
  authenticity_token: false,
  //new_block_type_id: false,
  block_types: false,
  modal: false,
  
  init: function(options)
  {
    for (var thing in options)
      this[thing] = options[thing];

    //this.set_block_type_editable();
    this.set_block_value_editable(this.block);
    this.set_child_blocks_editable();
    this.set_clickable();
  },
    
  edit_block: function(block_id)
  {
    window.location = '/admin/pages/' + this.block.page_id + '/blocks/' + block_id + '/edit';    
  },    
    
  /*****************************************************************************
  Block Rendering
  *****************************************************************************/

  set_clickable: function()
  {        
    var that = this;                
    $.ajax({      
      url: '/admin/pages/' + this.block.page_id + '/blocks/tree',
      success: function(blocks) {        
        $(blocks).each(function(i,b) {
          that.set_clickable_helper(b);                      
        });
      }
    });    
  },
    
  set_clickable_helper: function(b)
  {    
    var that = this;        
    $('#block_' + b.id).attr('onclick','').unbind('click');    
    $('#block_' + b.id).click(function(e) {
      e.stopPropagation();
      that.edit_block(b.id); 
    });
    if (b.allow_child_blocks == true)
    {
      $('#new_block_' + b.id).replaceWith($('<input/>')
        .attr('type', 'button')
        .val('New Block')
        .click(function(e) { e.stopPropagation(); that.new_block(b.id);          
        })
      );
    } 
    var show_mouseover = true;
    if (b.children && b.children.length > 0)
    {
      $.each(b.children, function(i, b2) {
        if (b2.block_type_id = 34)
          show_mouseover = false;
        that.set_clickable_helper(b2);
      });
    }    
    if (show_mouseover)
    {
      $('#block_' + b.id).mouseover(function(el) { $('#block_' + b.id).addClass(   'block_over'); });
      $('#block_' + b.id).mouseout(function(el)  { $('#block_' + b.id).removeClass('block_over'); }); 
    }    
  },

  /****************************************************************************/

  //set_block_type_editable: function()
  //{        
  //  var that = this;
  //  var b = this.block;    
  //  m = new ModelBinder({
  //    name: 'Block',
  //    id: b.id,
  //    update_url: '/admin/pages/' + b.page_id + '/blocks/' + b.id,
  //    authenticity_token: that.authenticity_token,
  //    attributes: [{      
  //      name: 'block_type_id',
  //      nice_name: 'Block type',
  //      type: 'select',
  //      value: b.block_type_id,             
  //      text: b.block_type.name,                  
  //      width: 400,
  //      fixed_placeholder: true,
  //      options_url: '/admin/block-types/options',
  //      after_update: function() { parent.controller.render_blocks(); window.location.reload(true); },
  //      after_cancel: function() { parent.controller.render_blocks(); window.location.reload(true); },
  //      on_load: function() { that.modal.autosize(); }
  //    },{      
  //      name: 'parent_id',
  //      nice_name: 'Parent ID',
  //      type: 'select',
  //      value: b.parent_id,
  //      text: b.parent_title,        
  //      width: 400,
  //      fixed_placeholder: true,        
  //      options_url: '/admin/pages/' + b.page_id + '/block-options',        
  //      after_update: function() { parent.controller.render_blocks(); },
  //      after_cancel: function() { parent.controller.render_blocks(); },
  //      on_load: function() { that.modal.autosize(); }
  //    }]
  //  });
  //  $('#advanced').hide();
  //},
  
  set_block_value_editable: function(b)
  {
    var that = this;    
    var bt = b.block_type;
    if (b.block_type.field_type == 'block') 
      return;
        
    var h = {
      name: 'value',
      type: bt.field_type,      
      nice_name: bt.description ? bt.description : bt.name,
      width: bt.width ? bt.width : 780,      
      after_update: function() { parent.controller.render_blocks(); },
      after_cancel: function() { parent.controller.render_blocks(); }
    };     
    h['value'] = b.value
    if (bt.field_type == 'checkbox')       h['value'] = b.value ? 'true' : 'false';
    if (bt.field_type == 'image')          h['value'] = b.image.tiny_url;
    if (bt.field_type == 'file')           h['value'] = b.image.url;                
    if (bt.field_type == 'select')         h['text'] = b.value;
    if (bt.height)                         h['height'] = bt.height;
    if (bt.fixed_placeholder)              h['fixed_placeholder'] = bt.fixed_placeholder;      
    if (bt.options || bt.options_function) h['options_url'] = '/admin/block-types/' + bt.id + '/options';
    else if (bt.options_url)               h['options_url'] = bt.options_url;
    if (bt.field_type == 'file')           h['update_url'] = '/admin/pages/' + b.page_id + '/blocks/' + b.id + '/file';
    if (bt.field_type == 'image')
    {
      h['update_url'] = '/admin/pages/' + b.page_id + '/blocks/' + b.id + '/image'
      h['image_refresh_delay'] = 100;
    }
        
    m = new ModelBinder({
      name: 'Block',
      id: b.id,
      update_url: '/admin/pages/' + b.page_id + '/blocks/' + b.id,
      authenticity_token: that.authenticity_token,
      attributes: [h]            
    });
  },
    
  set_child_blocks_editable: function()
  {
    var that = this;
    $.each(this.block.children, function(i, b) {
      var bt = b.block_type;      
      if (bt.field_type == 'block' || bt.field_type == 'richtext')
      {
        //$('#block_' + b.id).attr('onclick','').unbind('click');    
        //$('#block_' + b.id).click(function(e) {
        //  window.location = '/admin/pages/' + b.page_id + '/blocks/' + b.id + '/edit';               
        //});
      }
      else
        that.set_block_value_editable(b);           
    });
  },
  
  add_child_block: function(block_type_id)
  {
    var that = this;
    if (!this.block_types)
    {
      modal.autosize("<p class='loading'>Getting block types...</p>");
      $.ajax({
        url: '/admin/block-types/options',
        type: 'get',
        success: function(resp) {
          that.block_types = resp;
          that.add_child_block();
        }
      });
      return;
    }        
    if (!block_type_id)
    {
      var select = $('<select/>').attr('id', 'new_block_type_id');
      $.each(this.block_types, function(i, bt) {
        var opt = $('<option/>').val(bt.value).html(bt.text);
        select.append(opt);
      });            
      var p = $('<p/>').addClass('note warning')
        .append("Select a type of page block: ")
        .append(select)
        .append("<br/>")
        .append($('<input/>').attr('type','button').val('Confirm Add Block').click(function() { that.add_child_block($('#new_block_type_id').val()) })).append(' ')
        .append($('<input/>').attr('type','button').val('Cancel').click(function() { $('#message').empty(); modal.autosize(); }));
      modal.autosize(p);
      return;
    }
    modal.autosize("<p class='loading'>Adding block...</p>");
    $.ajax({
      url: '/admin/pages/' + that.block.page_id + '/blocks/' + that.block.id,
      type: 'post',
      data: { block_type_id: block_type_id },
      success: function(resp) {
        if (resp.error) modal.autosize("<p class='note error'>" + resp.error + "</p>");
        if (resp.block) window.location.reload(true);
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
        .append($('<input/>').attr('type','button').val('No').click(function() { $('#message').empty(); modal.autosize(); }));
      modal.autosize(p);
      return;
    }
    modal.autosize("<p class='loading'>Deleting block...</p>");
    $.ajax({
      url: '/admin/pages/' + that.block.page_id + '/blocks/' + that.block.id,
      type: 'delete',    
      success: function(resp) {
        if (resp.error) modal.autosize("<p class='note error'>" + resp.error + "</p>");
        if (resp.redirect) 
        {
          parent.controller.render_blocks();
          modal.close();
        }
      }
    });
  },
  
  move_up: function()
  {
    var that = this;
    modal.autosize("<p class='loading'>Moving up...</p>");
    $.ajax({
      url: '/admin/pages/' + that.block.page_id + '/blocks/' + that.block.id + '/move-up',
      type: 'put',    
      success: function(resp) {
        if (resp.error) modal.autosize("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) 
        {
          modal.autosize("<p class='note success'>" + resp.success + "</p>");          
          parent.controller.render_blocks();
        }
      }
    });    
  },
  
  move_down: function()
  {
    var that = this;
    modal.autosize("<p class='loading'>Moving down...</p>");
    $.ajax({
      url: '/admin/pages/' + that.block.page_id + '/blocks/' + that.block.id + '/move-down',
      type: 'put',    
      success: function(resp) {
        if (resp.error) modal.autosize("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) 
        {
          modal.autosize("<p class='note success'>" + resp.success + "</p>");          
          parent.controller.render_blocks();
        }
      }
    });    
  }
};
