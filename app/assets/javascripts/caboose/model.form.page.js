
Model.Form.Page = Model.Form.extend({
    
  class_name: 'Model.Form.Page',
  
  // Returns the form for editing a model or false for an embedded form.
  edit: function() 
  {
    var m = this.model;
    
    var this2 = this;
    var div = $('<div/>');
    $(m.attributes).each(function(i, a) {
      if (a.type == 'hidden')
        return;
      div.append(
        $('<div/>').attr('id', m.name + '_' + m.id + '_' + a.name + '_container')
      );
    });
    
    div.append($('<div/>').attr('id', this.message))
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').val('Back').click(function() { caboose_station.close_url('/pages/'+m.id+'/redirect'); }))
        .append(' ')
        .append($('<input/>').attr('type', 'button').val('Delete ' + m.name).click(function() { m.ajax_delete(); }))
      );
    return div;
  }
  
});
