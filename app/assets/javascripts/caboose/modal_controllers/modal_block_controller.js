
var ModalBlockController = ModalController.extend({

  block_types: false,
    
  init: function(options)
  {
    for (var thing in options)
      this[thing] = options[thing];

    //this.set_block_type_editable();
    this.set_block_value_editable(this.block);
    this.set_child_blocks_editable();
    this.set_clickable();
    
    that.update_on_close = false;
    $.each(that.block.children, function(i, b) {
      if (b.block_type.field_type == 'image' || b.block_type.field_type == 'file')
        that.update_on_close = true 
    });
            
  },
  
  base_url: function(b)
  {
    return '/admin/' + (b.page_id ? 'pages/' + b.page_id : 'posts/' + b.post_id) + '/blocks';        
  },
  
  block_url: function(b)
  {         
    return this.base_url(b) + '/' + b.id;          
  },
    
  edit_block: function(block_id)
  {    
    window.location = this.base_url(this.block) + '/' + block_id + '/edit';    
  },
  
  /*****************************************************************************
  Printing
  *****************************************************************************/
  
  crumbtrail: function()
  {
    var crumbs = $('<h2/>').css('margin-top', '0').css('padding-top', '0');
    var b = that.block;
    while (b)
    {      
      var href = b.id == that.block_id ? "#" : that.base_url + '/' + b.id;  
      var text = b.block_type.description + (b.name ? ' (' + b.name + ')' : '');
      crumbs.prepend($('<a/>').attr('href', href).html(text));      
      b = b.parent
      if (b) crumbs.prepend(' > ');
    }
    return crumbs;
  },
  
  print: function()
  {
    var that = this;
    
    if (!that.block)
    {
      var div = $('<div/>')
        .append($('<div/>').attr('id', 'crumbtrail'))
        .append($('<div/>').attr('id', 'modal_content'));
        .append($('<div/>').attr('id', 'modal_message'));        
        .append($('<p/>')  
          .append($('<input/>').attr('type', 'button').val('Close').click(function() {
            if (that.update_on_close)
              parent_controller.render_blocks();
            that.close();
          }))
<% if @block.name.nil? %>
  <input type='button' value='Delete Block' onclick="controller.delete_block();" />
<% end %>
<input type='button' value='Move Up'   onclick="controller.move_up();" />
<input type='button' value='Move Down' onclick="controller.move_down();" />
<input type='button' value='Advanced'  onclick="window.location='<%= raw base_url %>/<%= @block.id %>/advanced';" />
</p>

      that.modal(div, 800);
      that.refresh(function() { that.print(); });
      return;
    }
    
    var div = $('<div/>');
    
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
            div.append(b.rendered_value);
        });
      }              
      else
      {
        div.append($('<p/>').append("This block doesn't have any content yet."));
      }
      if (that.block.block_type.allow_child_blocks)
      {
        div.append($('<p/>').append($('<a/>').attr('href', '#').html("Add a child block!").click(function(e) {
          e.preventDefault();
          that.add_child_block();            
        })));            
      }
    }
    div.append($('<div/>').
  



<% content_for :caboose_css do %>
<style type='text/css'>
.block { border: #ccc 1px dotted; }
#block_<%= @block.id %>_block_type_id_container { }
#modal_content .checkbox_multiple input[type=checkbox] { position: relative !important; }
</style>
<% end %>
<% content_for :caboose_js do %>
<%= javascript_include_tag "caboose/model/all" %>
<%= javascript_include_tag "caboose/admin_block_edit" %>
<script type='text/javascript'>

var modal = false;
$(window).load(function() {  
  keep_modal_autosized();
});

var autosize_count = 0;
function keep_modal_autosized()
{
  if (autosize_count > 3) return;
  if (modal) modal.autosize();
  else modal = new CabooseModal(800);
  autosize_count = autosize_count + 1;
  setTimeout(function() { keep_modal_autosized(); }, 1000);
}


    
  },
    
  /*****************************************************************************
  Block Rendering
  *****************************************************************************/

  set_clickable: function()
  {        
    var that = this;                
    $.ajax({      
      url: that.base_url(that.block) + '/tree',
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
      url: that.block_url(block),
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
      url: that.block_url(that.block),
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
      url: that.block_url(that.block) + '/move-up',
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
      url: that.block_url(that.block) + '/move-down',
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
