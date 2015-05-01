
var ModificationsController = function(params) { this.init(params); };

ModificationsController.prototype = {

  product_id: false,
  mods: false,
  
  init: function(params) {
    for (var i in params)
      this[i] = params[i];
    this.refresh(true);
  },
  
  refresh: function(reprint) 
  {
    var that = this;
    $.ajax({
      url: '/admin/products/' + that.product_id + '/modifications/json',
      type: 'get',
      success: function(resp) {
        that.mods = resp;
        if (reprint)
        {
          that.print();
          that.make_editable();
        }
      }        
    });    
  },
  
  print: function() 
  {    
    var that = this;    
    $('#mods').empty()
      .append(that.mods_table())
      .append($('<div/>').attr('id', 'mods_message'))
      .append($('<input/>').attr('type', 'button').val('New Modification').click(function(e) { that.add_mod(); }));
  },
  
  make_editable: function()
  {    
    var that = this; 
    if (!that.mods || that.mods.length == 0)      
      return;

    $.each(that.mods, function(i, mod) {
      
      new ModelBinder({
        name: 'Modification',
        id: mod.id,
        update_url: '/admin/products/' + that.product_id + '/modifications/' + mod.id,
        authenticity_token: that.authenticity_token,
        attributes: [
          { name: 'name', nice_name: 'Modification Name', type: 'text', value: mod.name, width: 300, fixed_placeholder: true },                          
        ]
      });        
      if (mod.modification_values && mod.modification_values.length > 0)
      {
        $.each(mod.modification_values, function(j, mv) {
          new ModelBinder({
            name: 'ModificationValue',
            id: mv.id,
            update_url: '/admin/products/' + that.product_id + '/modifications/' + mod.id + '/values/' + mv.id,
            authenticity_token: that.authenticity_token,
            attributes: [              
              { name: 'value'             , nice_name: 'Value'             , type: 'text'     , value: mv.value                          , width: 150, fixed_placeholder: false },
              { name: 'is_default'        , nice_name: 'Default'           , type: 'checkbox' , value: mv.is_default ? true : false      , width:  75, fixed_placeholder: false , mod_id: mod.id, mv_id: mv.id, after_update: function() { that.check_default_value(this.mod_id, this.mv_id); }},
              { name: 'price'             , nice_name: 'Price'             , type: 'text'     , value: mv.price                          , width: 150, fixed_placeholder: false },
              { name: 'requires_input'    , nice_name: 'Requires Input'    , type: 'checkbox' , value: mv.requires_input ? true : false  , width: 150, fixed_placeholder: false },                         
              { name: 'input_description' , nice_name: 'Input Description' , type: 'text'     , value: mv.input_description              , width: 150, fixed_placeholder: false }
            ]
          });          
        });        
      }            
    });        
  },
  
  check_default_value: function(mod_id, mod_value_id, checked)
  {
    var that = this;    
    if ($('#modificationvalue_' + mod_value_id + '_is_default').is(':checked'))
    {            
      $.each(that.mods, function(i, mod) {        
        if (mod.id == mod_id)
        {
          $.each(mod.modification_values, function(j, mv) {            
            if (mv.id != parseInt(mod_value_id) && mv.is_default)
            {              
              $('#modificationvalue_' + mv.id + '_is_default').attr('checked', false);
              that.refresh();
            }              
          });          
        }          
      });
    }
  },
  
  mods_table: function()
  {
    var that = this; 
    if (!that.mods || that.mods.length == 0)      
      return $('<p/>').html("There are currently no modifications for this product.");
        
    var div = $('<div/>');
    
    $.each(that.mods, function(i, mod) {
      var mdiv = $('<div/>').addClass('modification'); 
      mdiv.append($('<div/>').attr('id', 'modification_' + mod.id + '_name'));        
      var mod_values = $('<div/>');
      if (mod.modification_values && mod.modification_values.length > 0)
      {        
        var tbody = $('<tbody>').append($('<tr/>')
          .append($('<th/>').html('Default'           ))
          .append($('<th/>').html('Value'             ))                         
          .append($('<th/>').html('Price'             ))
          .append($('<th/>').html('Requires Input'    ))                         
          .append($('<th/>').html('Input Description' ))
        );              
        $.each(mod.modification_values, function(j, mv) {
          tbody.append($('<tr/>')            
            .append($('<td/>').append($('<div/>').attr('id', 'modificationvalue_' + mv.id + '_is_default')))
            .append($('<td/>').append($('<div/>').attr('id', 'modificationvalue_' + mv.id + '_value')))
            .append($('<td/>').append($('<div/>').attr('id', 'modificationvalue_' + mv.id + '_price')))
            .append($('<td/>').append($('<div/>').attr('id', 'modificationvalue_' + mv.id + '_requires_input'    )))
            .append($('<td/>').append($('<div/>').attr('id', 'modificationvalue_' + mv.id + '_input_description' )))
            .append($('<td/>').append($('<input/>').attr('type', 'button').data('mod_id', mod.id).data('mod_value_id', mv.id).val('Remove').click(function(e) { that.delete_mod_value($(this).data('mod_id'), $(this).data('mod_value_id')); })))
          );
        });
        mod_values
          .append($('<table/>').append(tbody))
          .append($('<br/>'));
      }
      mdiv.append(mod_values);
      mdiv.append($('<div/>').attr('id', 'mod_' + mod.id + '_message'));
      mdiv
        .append($('<input/>').attr('type', 'button').data('mod_id', mod.id).val('New Value'           ).click(function(e) { that.add_mod_value($(this).data('mod_id')); })).append(' ')
        .append($('<input/>').attr('type', 'button').data('mod_id', mod.id).val('Remove Modification' ).click(function(e) { that.delete_mod($(this).data('mod_id'));    }));
      div.append(mdiv);
    });
    return div            
  },
  
  add_mod: function(name)
  {
    var that = this;    
    if (!name)
    {    
      var p = $('<p/>').addClass('note confirm')
        .append("Name: ")
        .append($('<input/>').attr('type','text').attr('id', 'new_mod_name').css('width', '200px')).append(' ')
        .append($('<input/>').attr('type','button').val('Add').click(function() { that.add_mod($('#new_mod_name').val()); })).append(' ')
        .append($('<input/>').attr('type','button').val('Cancel').click(function() { $('#mods_message').empty(); }));
      $('#mods_message').empty().append(p);
      return;
    }
    $('#mods_message').html("<p class='loading'>Adding...</p>");
    $.ajax({
      url: '/admin/products/' + that.product_id + '/modifications',
      type: 'post',
      data: { name: name },
      success: function(resp) {
        if (resp.error)     $('#mods_message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) { $('#mods_message').empty(); that.refresh(true); }        
      }
    });
  },
  
  add_mod_value: function(mod_id, value)
  {
    var that = this;    
    if (!value)
    {    
      var p = $('<p/>').addClass('note confirm')
        .append("Value: ")
        .append($('<input/>').attr('type','text').attr('id', 'new_mod_value').css('width', '200px')).append(' ')
        .append($('<input/>').attr('type','button').val('Add').click(function() { that.add_mod_value(mod_id, $('#new_mod_value').val()); })).append(' ')
        .append($('<input/>').attr('type','button').val('Cancel').click(function() { $('#mod_' + mod_id + '_message').empty(); }));
      $('#mod_' + mod_id + '_message').empty().append(p);
      return;
    }
    $('#mod_' + mod_id + '_message').html("<p class='loading'>Adding...</p>");
    $.ajax({
      url: '/admin/products/' + that.product_id + '/modifications/' + mod_id + '/values',
      type: 'post',
      data: { value: value },
      success: function(resp) {
        if (resp.error)     $('#mod_' + mod_id + '_message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) { $('#mod_' + mod_id + '_message').empty(); that.refresh(true); }        
      }
    });
  },
  
  delete_mod: function(mod_id, confirm)
  {
    var that = this;    
    if (!confirm)
    {    
      var p = $('<p/>').addClass('note confirm')
        .append("Are you sure you want to delete the modification? ")        
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.delete_mod(mod_id, true); })).append(' ')
        .append($('<input/>').attr('type','button').val('No' ).click(function() { $('#mod_' + mod_id + '_message').empty(); }));
      $('#mod_' + mod_id + '_message').empty().append(p);
      return;
    }
    $('#mod_' + mod_id + '_message').html("<p class='loading'>Removing...</p>");
    $.ajax({
      url: '/admin/products/' + that.product_id + '/modifications/' + mod_id,
      type: 'delete',      
      success: function(resp) {
        if (resp.error)     $('#mod_' + mod_id + '_message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) { $('#mod_' + mod_id + '_message').empty(); that.refresh(true); }        
      }
    });
  },
  
  delete_mod_value: function(mod_id, mod_value_id, confirm)
  {
    var that = this;    
    if (!confirm)
    {    
      var p = $('<p/>').addClass('note confirm')
        .append("Are you sure you want to delete the value? ")        
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.delete_mod_value(mod_id, mod_value_id, true); })).append(' ')
        .append($('<input/>').attr('type','button').val('No' ).click(function() { $('#mod_' + mod_id + '_message').empty(); }));
      $('#mod_' + mod_id + '_message').empty().append(p);
      return;
    }
    $('#mod_' + mod_id + '_message').html("<p class='loading'>Removing...</p>");
    $.ajax({
      url: '/admin/products/' + that.product_id + '/modifications/' + mod_id + '/values/' + mod_value_id,
      type: 'delete',      
      success: function(resp) {
        if (resp.error)     $('#mod_' + mod_id + '_message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) { $('#mod_' + mod_id + '_message').empty(); that.refresh(true); }        
      }
    });
  }
  
};
      