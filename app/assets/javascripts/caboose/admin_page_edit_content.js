
var PageContentEditor = function(page_id, auth_token) {
  this.page_id = page_id;
  this.auth_token = auth_token;
  this.render_blocks();
};

PageContentEditor.prototype = {

  page_id: false,
  current_block_id: false,
  
  render_blocks: function()
  {
    var that = this;
    $.ajax({
      url: '/admin/pages/' + this.page_id + '/blocks',
      success: function(blocks) {
        $(blocks).each(function(i,b) { that.render_block(b.id); });                
      }
    });    
  },
  
  render_block: function(block_id, after)
  {    
    var that = this;
    $.ajax({
      url: '/admin/pages/' + this.page_id + '/blocks/' + block_id + '/render?empty_text=[Empty, click to edit]',
      success: function(html) {
        $('#pageblock_' + block_id).empty().html(html);
        $('#pageblock_' + block_id).attr('onclick','').unbind('click');
        $('#pageblock_' + block_id).click(function(e) { that.edit_block(block_id); });
        if (that.current_block_id == block_id) that.current_block_id = false;
        if (after) after();
      }
    });
  },
  
  edit_block: function(block_id)
  {
    var that = this;
    if (this.current_block_id && this.current_block_id != block_id)
    {
      this.render_block(this.current_block_id, function() { that.edit_block(block_id); });
      return;
    }
      
    this.current_block_id = block_id;
    $('#pageblock_' + block_id).attr('onclick','').unbind('click');  
    $.ajax({
      url: '/admin/pages/' + this.page_id + '/blocks/' + block_id,
      success: function(block) {
        $('#pageblock_' + block.id).empty().append($('<div/>').attr('id', 'pageblock_' + block.id + '_value'));
        that["edit_" + block.block_type + "_block"](block);
      }            
    });
  },

  edit_h1_block: function(block) { return this.edit_text_block(block); },
  edit_h2_block: function(block) { return this.edit_text_block(block); },
  edit_h3_block: function(block) { return this.edit_text_block(block); },
  edit_h4_block: function(block) { return this.edit_text_block(block); },
  edit_h5_block: function(block) { return this.edit_text_block(block); },
  edit_h6_block: function(block) { return this.edit_text_block(block); },
  
  edit_text_block: function(block) {
    var that = this;
    m = new ModelBinder({
      name: 'PageBlock',
      id: block.id,
      update_url: '/admin/pages/' + this.page_id + '/blocks/' + block.id,
      authenticity_token: this.auth_token,
      attributes: [{ 
        name: 'value', 
        nice_name: 'Content', 
        type: 'text', 
        value: block.value, 
        width: 800, 
        fixed_placeholder: false,
        after_update: this.after_block_update,          
        after_cancel: this.after_block_cancel
      }],    
    });  
  },
  
  edit_richtext_block: function(block) {
    var that = this;
    m = new ModelBinder({
      name: 'PageBlock',
      id: block.id,
      update_url: '/admin/pages/' + this.page_id + '/blocks/' + block.id,
      authenticity_token: this.auth_token,
      attributes: [{ 
        name: 'value', 
        nice_name: 'Content', 
        type: 'richtext', 
        value: block.value, 
        width: 800, 
        height: 300,
        fixed_placeholder: false,
        after_update: function() { 
          //that.after_block_update(that);
          that.render_block(that.current_block_id);
          ModelBinder.remove_from_all_model_binders('PageBlock', that.current_block_id);
          that.current_block_id = false;
        },          
        after_cancel: function() { that.after_block_cancel(that); }
      }],    
    });  
  },
  
  after_block_update: function(pce) {
    pce.render_block(pce.current_block_id);
    ModelBinder.remove_from_all_model_binders('PageBlock', pce.current_block_id);
    pce.current_block_id = false;
  },

  after_block_cancel: function(pce) {
    pce.render_block(pce.current_block_id);
    ModelBinder.remove_from_all_model_binders('PageBlock', pce.current_block_id);
    pce.current_block_id = false;            
  }
}
