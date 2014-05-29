
var PageContentEditor = function(page_id, auth_token) {
  this.page_id = page_id;
  this.auth_token = auth_token;
  this.add_controls();
  this.render_blocks();
};

PageContentEditor.prototype = {

  page_id: false,
  current_block_id: false,  
  block_types: { h1: 'Heading 1', h2: 'Heading 2', h3: 'Heading 3', h4: 'Heading 4', h5: 'Heading 5', h6: 'Heading 6', richtext: 'Rich Text'},
  
  add_controls: function(id)
  {
    var that = this;
    //$('#block_controls').empty();          
    //$('#block_controls')
    //  .append($('<h2/>').attr('id', 'edit_blocks_header').html('Edit Blocks'))
    //  .append($('<div/>').addClass('content').append($('<p/>').html('Select a block to edit.')));
    $('#blocks').selectable({ 
      filter: "li", 
      cancel: ".handle",
      selected: function(e, ui) {
        var block_id = ui.selected.id.replace("block_container_", "");
        that.edit_block(block_id);         
      }
    });              
  },        
};
