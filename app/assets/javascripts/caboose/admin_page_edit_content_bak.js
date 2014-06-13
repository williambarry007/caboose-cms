
var PageContentController = function(page_id) { this.init(page_id); };

PageContentController.prototype = {

  page_id: false,    
  new_block_type_id: false,
  
  init: function(page_id)
  {
    this.page_id = page_id;
    var that = this;
    //this.render_blocks(function() {
    //  that.sortable_blocks();
    //  that.draggable_blocks();
    //});
  },
  
  sortable_blocks: function()
  { 
    var that = this;
    $('#blocks').sortable({
      //hoverClass: "ui-state-active",
      placeholder: 'sortable-placeholder',
      forcePlaceholderSize: true,
      handle: '.sort_handle',
      receive: function(e, ui) {      
        that.new_block_type_id = ui.item.attr('id').replace('new_block_', '');    
      },
      update: function(e, ui) {        
        if (that.new_block_type_id)
        {
          $.ajax({
            url: '/admin/pages/' + that.page_id + '/blocks',
            type: 'post',
            data: { block_type_id: that.new_block_type_id, index: ui.item.index() },
            success: function(resp) { that.render_blocks(function() { that.edit_block(resp.block.id); }); }
          });                    
          that.new_block_type_id = false;
        }
        else
        {        
          $.ajax({
            url: '/admin/pages/' + that.page_id + '/block-order',
            type: 'put',
            data: $('#blocks').sortable('serialize', { key: "block_ids[]" }),
            success: function(resp) {}
          });
        }
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
    caboose_modal_url('/admin/pages/' + this.page_id + '/blocks/' + block_id + '/edit');    
  },
  
  delete_block: function(block_id, confirm)
  {
    var that = this;        
    if (!confirm)
    {
      var p = $('<p/>')
        .addClass('note warning')
        .append("Are you sure you want to delete the block? ")
        .append($('<input/>').attr('type', 'button').val('Yes').click(function() { that.delete_block(block_id, true); })).append(" ")
        .append($('<input/>').attr('type', 'button').val('No').click(function() { that.render_block(block_id); }));
      $('#block_container_' + block_id).attr('onclick','').unbind('click');
      $('#block_container_' + block_id).empty().append(p);
      return;
    }
    $.ajax({
      url: '/admin/pages/' + this.page_id + '/blocks/' + block_id,
      type: 'delete',
      success: function(resp) {
        that.render_blocks();      
      }
    });    
  },
    
  /*****************************************************************************
  Block Rendering
  *****************************************************************************/

  render_blocks: function(after)
  {
    $('#blocks').empty();    
    var that = this;
    $.ajax({      
      url: '/admin/pages/' + this.page_id + '/blocks/render?empty_text=[Empty, click to edit]',
      success: function(blocks) {
        if (blocks.length == 0)
        {
          $('#blocks').parent().append("<p>This page is empty.  Please add a new block.</p>");
        }          
        $(blocks).each(function(i,b) {
          $('#blocks')
            .append($('<li/>')
              .attr('id', 'block_container_' + b.id)                                          
              //.append($('<a/>').attr('id', 'block_' + b.id + '_sort_handle'  ).addClass('sort_handle'  ).append($('<span/>').addClass('ui-icon ui-icon-arrow-2-n-s')))
              //.append($('<a/>').attr('id', 'block_' + b.id + '_delete_handle').addClass('delete_handle').append($('<span/>').addClass('ui-icon ui-icon-close')).click(function(e) { e.preventDefault(); that.delete_block(b.id); }))
              //.append($('<div/>').attr('id', 'block_' + b.id).addClass('block'))
            );
        });                
        $(blocks).each(function(i,b) { 
          that.render_block_html(b.id, b.html); 
        });
        that.set_clickable();        
        if (after) after();
      }
    });    
  },
  
  render_block_html: function(block_id, html)
  {        
    var that = this;    
    $('#block_container_' + block_id).empty().html(html);    
  },
  
  set_clickable: function()
  {        
    var that = this;                
    $.ajax({      
      url: '/admin/pages/' + this.page_id + '/blocks/tree',
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
    if (!b.children || b.children.length == 0)
    {      
      $('#block_' + b.id).attr('onclick','').unbind('click');    
      $('#block_' + b.id).click(function(e) { that.edit_block(b.id); });
    }
    else
    {      
      $.each(b.children, function(i, b2) {
        that.set_clickable_helper(b2);
      });
    }
  }
};

function toggle_blocks()
{
  $('#new_blocks_container2').slideToggle();
}
