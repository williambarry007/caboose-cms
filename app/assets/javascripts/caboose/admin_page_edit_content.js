 
var PageContentController = function(params) { this.init(params); };

PageContentController.prototype = {

  page_id: false,    
  new_block_type_id: false,
  selected_block_ids: [],
  blocks: false,
  assets_path: false,
  included_assets: false,
  
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];      
    that.refresh_blocks(function() {
      that.set_clickable();
    });        
  },
  
  refresh_blocks: function(callback)
  {
    var that = this;
    $.ajax({
      url: '/admin/pages/' + that.page_id + '/blocks/tree',
      type: 'get',
      success: function(resp) {
        that.blocks = resp;
        if (callback) callback();
      }
    });    
  },
  
  draggable_blocks: function() 
  {
    $('#new_blocks li').draggable({
      dropOnEmpty: true,
      connectToSortable: "#blocks",
      helper: "clone",
      revert: "invalid"    
    });    
  },
    
  edit_block: function(block_id)
  {     
    console.log('PageContentController.edit_block');
    var that = this;
    var b = that.block_with_id(block_id);
    var modal_controller = '';    
    if (b.block_type.use_js_for_modal == true) {
      if (b.name)
        $.each(b.name.split('_'), function(j, word) { modal_controller += word.charAt(0).toUpperCase() + word.toLowerCase().slice(1); });
      else
        $.each(b.block_type.name.split('_'), function(j, word) { modal_controller += word.charAt(0).toUpperCase() + word.toLowerCase().slice(1); });      
    }    
    else if (b.block_type.field_type == 'image')    { modal_controller = 'Media';    }
    else if (b.block_type.field_type == 'richtext') { modal_controller = 'Richtext'; }
    else                                            { modal_controller = 'Block';    }    
    that.modal = eval("new " + modal_controller + "ModalController({ " +
      "  page_id: " + that.page_id + ", " +
      "  block_id: " + block_id + ", " + 
      "  authenticity_token: '" + that.authenticity_token + "', " + 
      "  parent_controller: this, " +
      "  assets_path: '" + that.assets_path + "'" +
      "})"
    );
  },
  
  new_block: function(parent_id, before_block_id, after_block_id)
  {
    console.log('PageContentController.new_block');
    var that = this;
    //caboose_modal_url('/admin/pages/' + this.page_id + '/blocks/' + parent_id + '/new');
    that.modal = new BlockModalController({ 
      page_id: that.page_id,
      block_id: parent_id,
      authenticity_token: that.authenticity_token,
      parent_controller: this,      
      assets_path: that.assets_path,
      new_block_on_init: true
    })
  },
  
  select_block: function(block_id)
  {            
    i = this.selected_block_ids.indexOf(block_id);
    if (i == -1) // Not there
    {
      this.selected_block_ids.push(block_id);
      $('#block_' + block_id).addClass('selected');
    }
    else
    {
      this.selected_block_ids.splice(i, 1);
      $('#block_' + block_id).removeClass('selected');
    }    
  },
  
  delete_block: function(block_id, confirm)
  {
    var that = this;        
    if (!confirm)
    {
      if (this.selected_block_ids.indexOf(block_id) == -1)
        this.selected_block_ids.push(block_id);
      var other_count = this.selected_block_ids.length - 1;
      
      var message = "Are you sure you want to delete this block";      
      if (other_count > 0)
        message += " and the " + other_count + " other selected block" + (other_count == 1 ? '' : 's');
      message += "?<br />";
      
      var p = $('<p/>')
        .addClass('caboose_note')
        .append(message)
        .append($('<input/>').attr('type', 'button').val('Yes').click(function(e) { e.preventDefault(); e.stopPropagation(); that.delete_block(block_id, true); })).append(" ")
        .append($('<input/>').attr('type', 'button').val('No').click(function(e) {  e.preventDefault(); e.stopPropagation(); that.render_blocks(); }));
      $('#block_' + block_id).attr('onclick','').unbind('click');
      $('#block_' + block_id).empty().append(p);
      return;
    }
    for (var i in this.selected_block_ids)
    {               
      $.ajax({
        url: '/admin/pages/' + this.page_id + '/blocks/' + this.selected_block_ids[i],
        type: 'delete',
        async: false,
        success: function(resp) {}
      });
    }
    that.render_blocks();
  },
  
  move_block_up: function(block_id)
  {
    var that = this;
    this.loadify($('#block_' + block_id + '_move_up_handle span'));    
    $.ajax({
      url: '/admin/pages/' + this.page_id + '/blocks/' + block_id + '/move-up',
      type: 'put',      
      success: function(resp) {        
        if (resp.success) that.render_blocks(function() { that.stop_loadify(); });      
      }
    });    
  },
  
  move_block_down: function(block_id)
  {   
    var that = this;
    this.loadify($('#block_' + block_id + '_move_down_handle span'));
    $.ajax({
      url: '/admin/pages/' + this.page_id + '/blocks/' + block_id + '/move-down',
      type: 'put',      
      success: function(resp) {        
        if (resp.success) that.render_blocks(function() { that.stop_loadify(); });      
      }
    });    
  },
  
  loadify: function(el)
  {
    var that = this;
    if      (el.hasClass('ui-icon-arrowrefresh-1-e')) el.removeClass('ui-icon-arrowrefresh-1-e').addClass('ui-icon-arrowrefresh-1-s');
    else if (el.hasClass('ui-icon-arrowrefresh-1-s')) el.removeClass('ui-icon-arrowrefresh-1-s').addClass('ui-icon-arrowrefresh-1-w');
    else if (el.hasClass('ui-icon-arrowrefresh-1-w')) el.removeClass('ui-icon-arrowrefresh-1-w').addClass('ui-icon-arrowrefresh-1-n');
    else if (el.hasClass('ui-icon-arrowrefresh-1-n')) el.removeClass('ui-icon-arrowrefresh-1-n').addClass('ui-icon-arrowrefresh-1-e');
    else el.addClass('ui-icon-arrowrefresh-1-e');
    this.loadify_el = el;
    this.loadify_timer = setTimeout(function() { that.loadify(el); }, 200);                       
  },
  
  stop_loadify: function()
  {
    if (this.loadify_el)
    {
      this.loadify_el.removeClass('ui-icon-arrowrefresh-1-e')
        .removeClass('ui-icon-arrowrefresh-1-s')
        .removeClass('ui-icon-arrowrefresh-1-w')
        .removeClass('ui-icon-arrowrefresh-1-n');
    } 
    if (this.loadify_timer)
      clearTimeout(this.loadify_timer);                
  },
    
  /*****************************************************************************
  Block Rendering
  *****************************************************************************/
  
  render_blocks: function(before_render) 
  {
    var that = this;
    $('.sortable').sortable('destroy');
    var that = this;                
    $.ajax({
      url: '/admin/pages/' + this.page_id + '/blocks/render-second-level',
      success: function(blocks) {        
        if (before_render) before_render();
        $(blocks).each(function(i, b) {
          $('#block_' + b.id).replaceWith(b.html);                              
        });
        that.refresh_blocks(function() { that.set_clickable(); });                
        that.selected_block_ids = [];
      }
    });
  },                                                                                                                               
         
  set_clickable: function()
  {            
    var that = this;            
    var count = that.blocks.length;        
    $(that.blocks).each(function(i,b) {
      that.set_clickable_helper(b, false, false, (i == count-1));
    });                    
  },
  
  set_clickable_helper: function(b, parent_id, parent_allows_child_blocks, is_last_child)
  {
    var that = this;
        
    $('#block_' + b.id)      
      .prepend($('<a/>').attr('id', 'block_' + b.id + '_select_handle'    ).addClass('select_handle'    ).append($('<span/>').addClass('ui-icon ui-icon-check'      )).click(function(e) { e.preventDefault(); e.stopPropagation(); that.select_block(b.id);    }))      
      .prepend($('<a/>').attr('id', 'block_' + b.id + '_move_up_handle'   ).addClass('move_up_handle'   ).append($('<span/>').addClass('ui-icon ui-icon-arrow-1-n'  )).click(function(e) { e.preventDefault(); e.stopPropagation(); that.move_block_up(b.id);   }))
      .prepend($('<a/>').attr('id', 'block_' + b.id + '_move_down_handle' ).addClass('move_down_handle' ).append($('<span/>').addClass('ui-icon ui-icon-arrow-1-s'  )).click(function(e) { e.preventDefault(); e.stopPropagation(); that.move_block_down(b.id); }))
      .prepend($('<a/>').attr('id', 'block_' + b.id + '_delete_handle'    ).addClass('delete_handle'    ).append($('<span/>').addClass('ui-icon ui-icon-close'      )).click(function(e) { e.preventDefault(); e.stopPropagation(); that.delete_block(b.id);    }));
      
    if (parent_allows_child_blocks && (!b.name || b.name.length == 0))
    {            
      $('#block_' + b.id).before($('<div/>')          
        .addClass('new_block_link')
        .append($('<div/>').addClass('line'))
        .append($('<a/>')
          .attr('href', '#')
          .html("New Block")
          .click(function(e) { 
            e.preventDefault(); e.stopPropagation();
            console.log('Adding new block...');
            that.new_block(parent_id, b.id);
          })
        )
        .mouseover(function(e) { $(this).removeClass('new_block_link').addClass('new_block_link_over'); e.stopPropagation(); })
        .mouseout(function(e)  { $(this).removeClass('new_block_link_over').addClass('new_block_link'); e.stopPropagation(); })
      );
      if (is_last_child && is_last_child == true)
      {
        $('#block_' + b.id).after($('<div/>')          
          .addClass('new_block_link')
          .append($('<div/>').addClass('line'))
          .append($('<a/>')
            .attr('href', '#')
            .html("New Block")
            .click(function(e) { 
              e.preventDefault(); e.stopPropagation();
              console.log('Adding new block...');
              that.new_block(parent_id, null, b.id);
            })
          )
          .mouseover(function(e) { $(this).removeClass('new_block_link').addClass('new_block_link_over'); e.stopPropagation(); })
          .mouseout(function(e)  { $(this).removeClass('new_block_link_over').addClass('new_block_link'); e.stopPropagation(); })
        );
      }
    }
    
    $('#block_' + b.id + ' *').attr('onclick', '').unbind('click');
    $('#block_' + b.id).attr('onclick','').unbind('click');
    $('#block_' + b.id).click(function(e) {
      e.preventDefault();
      e.stopPropagation();
      that.edit_block(b.id); 
    });
     
    var show_mouseover = true;
    if (b.children && b.children.length > 0)
    {
      var count = b.children.length;
      $.each(b.children, function(i, b2) {        
        if (b2.block_type.field_type == 'block')
          show_mouseover = false;
        that.set_clickable_helper(b2, b.id, b.block_type.allow_child_blocks, i == (count-1));
      });            
    }
    //if (b.allow_child_blocks)
    //{      
    //  $('#block_' + b.id).after($('<div/>')          
    //    .addClass('new_block_link')
    //    .append($('<div/>').addClass('line'))
    //    .append($('<a/>')
    //      .attr('href', '#')
    //      .html("New Block")
    //      .click(function(e) { 
    //        e.preventDefault(); e.stopPropagation();
    //        caboose_modal_url('/admin/pages/' + that.page_id + '/blocks/' + b.id + '/new?after_id=' + b.id);                        
    //      })
    //    )
    //    .mouseover(function(e) { $(this).removeClass('new_block_link').addClass('new_block_link_over'); e.stopPropagation(); })
    //    .mouseout(function(e)  { $(this).removeClass('new_block_link_over').addClass('new_block_link'); e.stopPropagation(); })
    //  );
    //}
    if (show_mouseover)
    {
      $('#block_' + b.id).mouseover(function(el) { $('#block_' + b.id).addClass(   'block_over'); });
      $('#block_' + b.id).mouseout(function(el)  { $('#block_' + b.id).removeClass('block_over'); }); 
    }    
  },
  
  /*****************************************************************************
  Helper methods
  *****************************************************************************/
  
  block_with_id: function(block_id, b)
  {
    var that = this;                
    if (b && b.id == block_id)
      return b;
    var the_block = false;
    if ((!b && that.blocks) || (b && b.children))
    {
      $.each(b ? b.children : that.blocks, function(i, b2) {        
        the_block = that.block_with_id(block_id, b2);
        if (the_block)
          return false;
      });
    }
    return the_block;
  }      
};

function toggle_blocks()
{
  $('#new_blocks_container2').slideToggle();
}


