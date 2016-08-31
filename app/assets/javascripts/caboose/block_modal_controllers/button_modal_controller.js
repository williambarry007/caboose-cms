
var ButtonModalController = BlockModalController.extend({
  
  print: function()
  {
    var that = this;
    
    if (!that.block)
    {
      var div = $('<div/>')
        .append($('<div/>').attr('id', 'modal_content'))
        .append($('<div/>').attr('id', 'modal_message').html("<p class='loading'>Getting block...</p>"))
        .append($('<p/>').append($('<input/>').attr('type', 'button').addClass('btn').val('Close').click(function(e) { $.colorbox.close(); })));      
      that.modal(div, 500, 200);                
      that.refresh(function() { that.print(); });      
      return;
    }
    
    var block_ids = {};
    $.each(that.block.children, function(i, b) {      
      block_ids[b.name] = b.id; 
    });    
        
    $('#modal_content').empty()
      .append($('<h2/>').append('Edit Button'))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + block_ids['text'   ] + '_text'   )))
      .append($('<p/>').append("Where do you want your button to go?"))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + block_ids['url'    ] + '_url'    )))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + block_ids['file'   ] + '_file'   )))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + block_ids['target' ] + '_target' )))
      .append($('<p/>').append("Options"))      
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + block_ids['align'  ] + '_align'  )))
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + block_ids['color'  ] + '_color'  )))      
      .append($('<p/>').append($('<div/>').attr('id', 'block_' + block_ids['margin' ] + '_margin' )));      
    $('#modal_message').empty();
    that.autosize();
        
    $.each(that.block.children, function(i, b) {      
      var attribs = [];
      if (b.name == 'text'   ) attribs.push({ name: 'text'   , nice_name: 'Button Text' , type: 'text'   , value: that.block.text    , width: 500 });
      if (b.name == 'url'    ) attribs.push({ name: 'url'    , nice_name: 'URL'         , type: 'text'   , value: that.block.url     , width: 500 });
      if (b.name == 'file'   ) attribs.push({ name: 'file'   , nice_name: 'File'        , type: 'text'   , value: that.block.file    , width: 500 });
      if (b.name == 'align'  ) attribs.push({ name: 'align'  , nice_name: 'Align'       , type: 'select' , value: that.block.align   , width: 500 , options_url: '/admin/block-types/' + b.block_type_id + '/options' });     
      if (b.name == 'color'  ) attribs.push({ name: 'color'  , nice_name: 'Color'       , type: 'select' , value: that.block.color   , width: 500 , options_url: '/admin/block-types/' + b.block_type_id + '/options' });        
      if (b.name == 'margin' ) attribs.push({ name: 'margin' , nice_name: 'Margin'      , type: 'select' , value: that.block.margin  , width: 500 , options_url: '/admin/block-types/' + b.block_type_id + '/options' });
      if (b.name == 'target' ) attribs.push({ name: 'target' , nice_name: 'Open in New Window?', type: 'checkbox' , value: that.block.target == 'New Window' ? 1 : 0  , width: 500 });

      new ModelBinder({
        name: 'Block',
        id: b.id,
        update_url: '/admin/pages/' + that.page_id + '/blocks/' + b.id,
        authenticity_token: that.authenticity_token,
        attributes: attribs,
        on_load: function() { that.autosize(); }
      });
      setTimeout(function() { that.autosize(); }, 2000);
    });
  }
  
});

$(document).trigger('button_modal_controller_loaded');
