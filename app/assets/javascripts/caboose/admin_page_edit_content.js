 
var PageContentController = function(page_id) { this.init(page_id); };

PageContentController.prototype = {

  page_id: false,    
  new_block_type_id: false,
  selected_block_ids: [],
  
  init: function(page_id)
  {
    this.page_id = page_id;
    var that = this;
    that.set_clickable();       
    that.sortable_blocks();
    //  that.draggable_blocks();
    //});
  },
  
  sortable_blocks: function()
  { 
    //var that = this;
    //$('.sortable').sortable({
    //  //hoverClass: "ui-state-active",
    //  placeholder: 'sortable-placeholder',
    //  forcePlaceholderSize: true,
    //  handle: '.sort_handle',
    //  receive: function(e, ui) {      
    //    that.new_block_type_id = ui.item.attr('id').replace('new_block_', '');    
    //  },
    //  update: function(e, ui) {        
    //    if (that.new_block_type_id)
    //    {
    //      $.ajax({
    //        url: '/admin/pages/' + that.page_id + '/blocks',
    //        type: 'post',
    //        data: { block_type_id: that.new_block_type_id, index: ui.item.index() },
    //        success: function(resp) { that.render_blocks(function() { that.edit_block(resp.block.id); }); }
    //      });                    
    //      that.new_block_type_id = false;
    //    }
    //    else
    //    {
    //      var ids = [];
    //      $.each($(e.target).children(), function(i, el) {
    //        var id = $(el).attr('id');            
    //        if (id && id.substr(0, 6) == 'block_') ids.push(id.substr(6));
    //      });          
    //        
    //      $.ajax({
    //        url: '/admin/pages/' + that.page_id + '/block-order',
    //        type: 'put',
    //        data: {
    //          block_ids: ids,
    //        },
    //        success: function(resp) {}
    //      });
    //    }
    //  }
    //});
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
    caboose_modal_url('/admin/pages/' + this.page_id + '/blocks/' + block_id + '/edit');    
  },
  
  new_block: function(block_id)
  {
    caboose_modal_url('/admin/pages/' + this.page_id + '/blocks/' + block_id + '/new');    
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
        that.stop_loadify();
        if (resp.success) that.render_blocks();      
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
        that.stop_loadify();
        if (resp.success) that.render_blocks();      
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
  
  render_blocks: function() {
    $('.sortable').sortable('destroy');
    var that = this;                
    $.ajax({
      url: '/admin/pages/' + this.page_id + '/blocks/render-second-level',
      success: function(blocks) {
        $(blocks).each(function(i, b) {
          $('#block_' + b.id).replaceWith(b.html);                              
        });
        that.set_clickable();
        that.sortable_blocks();
        that.selected_block_ids = [];
      }
    });
  },                                                                                                                               
         
  set_clickable: function()
  {        
    var that = this;                
    $.ajax({      
      url: '/admin/pages/' + this.page_id + '/blocks/tree',
      success: function(blocks) {
        var count = blocks.length;        
        $(blocks).each(function(i,b) {
          that.set_clickable_helper(b, false, false, (i == count-1));
        });        
      }
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
      $('#block_' + b.id).prepend($('<div/>')          
        .addClass('new_block_link')
        .append($('<div/>').addClass('line'))
        .append($('<a/>')
          .attr('href', '#')
          .html("New Block")
          .click(function(e) { 
            e.preventDefault(); e.stopPropagation();
            caboose_modal_url('/admin/pages/' + that.page_id + '/blocks/' + parent_id + '/new?before_id=' + b.id);                        
          })
        )
        .mouseover(function(e) { $(this).removeClass('new_block_link').addClass('new_block_link_over'); e.stopPropagation(); })
        .mouseout(function(e)  { $(this).removeClass('new_block_link_over').addClass('new_block_link'); e.stopPropagation(); })
      );
      if (is_last_child && is_last_child == true)
      {
        $('#block_' + b.id).append($('<div/>')          
          .addClass('new_block_link')
          .append($('<div/>').addClass('line'))
          .append($('<a/>')
            .attr('href', '#')
            .html("New Block")
            .click(function(e) { 
              e.preventDefault(); e.stopPropagation();
              caboose_modal_url('/admin/pages/' + that.page_id + '/blocks/' + parent_id + '/new?after_id=' + b.id);                        
            })
          )
          .mouseover(function(e) { $(this).removeClass('new_block_link').addClass('new_block_link_over'); e.stopPropagation(); })
          .mouseout(function(e)  { $(this).removeClass('new_block_link_over').addClass('new_block_link'); e.stopPropagation(); })
        );
      }
    }
            
    $('#block_' + b.id).attr('onclick','').unbind('click');    
    $('#block_' + b.id).click(function(e) {
      e.stopPropagation();
      that.edit_block(b.id); 
    });
     
    var show_mouseover = true;
    if (b.children && b.children.length > 0)
    {
      var count = b.children.length;
      $.each(b.children, function(i, b2) {        
        if (b2.field_type == 'block')
          show_mouseover = false;
        that.set_clickable_helper(b2, b.id, b.allow_child_blocks, i == (count-1));
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
  }    
  
};

function toggle_blocks()
{
  $('#new_blocks_container2').slideToggle();
}


