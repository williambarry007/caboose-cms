
var IndexTable = function(params) { this.init(params); }
IndexTable.prototype = {
  
  //============================================================================
  // Required parameters   
  //============================================================================
  
  form_authenticity_token: false,
  
  // Base URL used for default refresh/update/delete/bulk URLs
  base_url: false,
    
  // Where to get json data for all the models  
  refresh_url: false,  
  
  // Where to send bulk updates
  bulk_update_url: false,
  
  // Where to send bulk deletes
  bulk_delete_url: false,
  
  // Where to post new models
  add_url: false,
  
  // Array of fields you want to show in the table (given as model binder attributes with additional text and value functions)
  // [{ 
  //   show: true,
  //   bulk_edit: true,
  //   name: 'title',
  //   nice_name: 'Title',
  //   type: 'text',
  //   text: function(obj) { return obj.title; },
  //   value: function(obj) { return obj.id; },
  //   options_url: '/admin/dogs/collar-options'
  //   fixed_placeholder: false,
  //   width: 200,   
  // }]
  fields: [],
  
  //============================================================================
  // Additional parameters
  //============================================================================

  // Container for the table
  container: 'models',
  
  // Where to get json data for a single model
  refresh_single_url: function(model_id, it) { return it.base_url + '/' + model_id + '/json'; },
    
  // Where to send normal updates    
  update_url: function(model_id, it) { return it.base_url + '/' + model_id; },
  
  // Where to send duplicate calls  
  duplicate_url: function(model_id, it) { return it.base_url + '/' + model_id + '/duplicate'; },
  
  // What to do when the edit button is clicked for a model 
  edit_click_handler: function(model_id, it) { window.location = it.base_url + '/' + model_id; },
  
  // What to do when a row is click. Default is quick edit mode.
  row_click_handler: function(model_id, it, e) {                  
    if (it.quick_edit_model_id == model_id)
    {
      if ($(e.target).prop('tagName') == 'TD')
        it.quick_edit_model_id = false;          
      else
        return;
    }
    else        
      it.quick_edit_model_id = model_id;
    it.print();       
  },    
    
  allow_bulk_edit: true,
  allow_bulk_delete: true,
  allow_duplicate: true,
  allow_advanced_edit: true,  
  no_models_text: "There are no models right now.",
  new_model_text: 'New',
  new_model_fields: [{ name: 'name', nice_name: 'Name', type: 'text', width: 400 }],
          
  //============================================================================
  // End of parameters
  //============================================================================
  
  models: [], // The models we get from the server
  model_ids: [], // IDs of currently selected models
  quick_edit_model_id: false, // The id of the model currently being edited      
  pager: { 
    options: { page: 1 }, 
    params: {}
  },
  
  // Constructor
  init: function(params) {
    for (var thing in params)
      this[thing] = params[thing];    
        
    var that = this;
    if (!this.refresh_url          ) this.refresh_url           = this.base_url + '/json';
    if (!this.bulk_update_url      ) this.bulk_update_url       = this.base_url + '/bulk';    
    if (!this.bulk_delete_url      ) this.bulk_delete_url       = this.base_url + '/bulk';
    if (!this.add_url              ) this.add_url               = this.base_url;
         
    $.each(this.fields, function(i, f) {
      if (f.editable == null) f.editable = true;
    });

    $(window).on('hashchange', function() { that.refresh(); });        
    this.refresh();
  },
  
  parse_querystring: function()
  {
    var b = {};
    
    // Get the hash values
    var a = window.location.hash;    
    if (a.length > 0)
    {
      a = a.substr(1).split('&');
      for (var i=0; i<a.length; ++i)
      {
        var p = a[i].split('=', 2);
        if (p.length == 1) b[p[0]] = "";
        else b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
      }
    }          
    
    // Get the querystring values
    a = window.location.search;
    if (a.length > 0)
    {
      a = a.substr(1).split('&');
      for (var i=0; i<a.length; ++i)
      {
        var p = a[i].split('=', 2);
        if (p.length == 1) b[p[0]] = "";
        else b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
      }
    }
    
    // Set both hash and querystring values in the pager
    for (var i in b)
    {
      if (i == 'sort' || i == 'desc' || i == 'page')      
        this.pager.options[i] = b[i];
      else
        this.pager.params[i] = b[i];              
    }
    
    // If there's a querystring, then redirect to hash
    //if (window.location.search.length > 0)
    //{
    //  //alert('Testing');      
    //  //window.location = this.pager_url({ base_url: window.location.pathname }).replace('?', '#');      
    //}
  },

  refresh: function()
  {
    this.pager = { options: { page: 1 }, params: {}};
    this.parse_querystring();
        
    var that = this;
    var $el = $('#' + this.container + '_columns').length > 0 ? $('#' + this.container + '_table_container') : $('#' + this.container);
    $el.html("<p class='loading'>Refreshing...</p>");        
    $.ajax({
      url: that.refresh_url,
      type: 'get',
      data: that.pager_params(),
      success: function(resp) {
        for (var thing in resp['pager'])
          that.pager[thing] = resp['pager'][thing];                
        that.models = resp['models'];
        for (var i=0; i<that.models.length; i++)
        {
          var m = that.models[i];                              
          m.id = parseInt(m.id);          
        }        
        that.print();                        
      },
      error: function() { $('#' + this.container).html("<p class='note error'>Error retrieving data.</p>"); }
    });
  },
  
  refresh_single: function(model_id)
  {            
    var that = this;                
    $.ajax({ 
      url: that.refresh_single_url(model_id, that),
      type: 'get',      
      success: function(resp) {
        for (var i=0; i<that.models.length; i++)
        {
          if (that.models[i].id == model_id)
          {
            that.models[i] = resp;
            break;
          }                      
        }
      }      
    });
  },
  
  print: function()
  {
    var that = this;
    
    if (that.models == null || that.models.length == 0)
    {
      $('#' + that.container).empty()
        .append($('<p/>').append(that.new_model_link()))
        .append($('<div/>').attr('id', that.container + '_new_form_container'))        
        .append($('<p/>').append(that.no_models_text));            
      return;
    }

    var tbody = $('<tbody/>').append(this.table_headers());            
    $.each(that.models, function(i, m) {
      tbody.append(that.table_row(m));
    });                                
    var table = $('<table/>').addClass('data').css('margin-bottom', '10px').append(tbody);
    var pager_div = this.pager_div();    
        
    if ($('#' + this.container + '_columns').length > 0)
    {
      $('#' + this.container + '_table_container').empty().append(table);
      $('#' + this.container + '_pager').empty().append(pager_div);
      $('#' + this.container + '_new_form_container').empty();
    }
    else
    {
      var columns = this.column_checkboxes();            
      var controls = $('<p/>');
      if (this.allow_bulk_edit   ) controls.append($('<input/>').attr('type', 'button').attr('id', this.container + '_bulk_edit'  ).val('Bulk Edit'  ).click(function(e) { that.bulk_edit();   })).append(' ');
      if (this.allow_bulk_delete ) controls.append($('<input/>').attr('type', 'button').attr('id', this.container + '_bulk_delete').val('Bulk Delete').click(function(e) { that.bulk_delete(); })).append(' ');
      if (this.allow_duplicate   ) controls.append($('<input/>').attr('type', 'button').attr('id', this.container + '_duplicate'  ).val('Duplicate'  ).click(function(e) { that.duplicate();   }));
      
      $('#' + that.container).empty()
        .append($('<p/>')
          .append(that.new_model_link()).append(' | ')          
          .append($('<a/>').attr('href', '#').html('Show/Hide Columns').click(function(e) { e.preventDefault(); $('#' + that.container + '_columns').slideToggle(); }))
        )
        .append($('<div/>').attr('id', that.container + '_new_form_container'))        
        .append($('<div/>').attr('id', that.container + '_columns').append(columns))
        .append($('<div/>').attr('id', that.container + '_table_container').append(table))        
        .append($('<div/>').attr('id', that.container + '_pager').append(pager_div))        
        .append($('<div/>').attr('id', that.container + '_message'))
        .append(controls);        
      $('#' + that.container + '_columns').hide();
    }    

    if (that.quick_edit_model_id)
    {      
      var m = that.model_for_id(that.quick_edit_model_id);
      $.each(that.fields, function(j, field) {
        if (field.show && field.editable)
        {            
          var attrib = $.extend({}, field);
          attrib['value'] = field.value(m);
          attrib['fixed_placeholder'] = false;
          attrib['after_update'] = function() { that.refresh_single(m.id); };          
          new ModelBinder({
            name: 'Model',
            id: m.id,
            update_url: that.update_url(m.id, that),
            authenticity_token: that.form_authenticity_token,
            attributes: [attrib]            
          });
        }
      });      
    }
  },
  
  all_models_selected: function()
  {    
    var that = this;
    var all_checked = true;
    $.each(that.models, function(i, m) {
      if (that.model_ids.indexOf(m.id) == -1)
      {
        all_checked = false;
        return false;
      }
    });
    return all_checked;
  },      
  
  table_headers: function()
  {
    var that = this;    
    var tr = $('<tr/>');
    
    if (this.allow_bulk_edit || this.allow_bulk_delete || this.allow_duplicate)
    {
      var input = $('<input/>').attr('type', 'checkbox').attr('id', that.container + '_check_all').val(1)            
        .change(function() {
          var checked = $(this).prop('checked');
          that.model_ids = [];          
          $.each(that.models, function(i, m) {
            $('#model_' + m.id).prop('checked', checked);
            if (checked) that.model_ids.push(m.id);
          });
        });      
      input.prop('checked', that.all_models_selected());
      tr.append($('<th/>').append(input));
    }
    if (this.allow_advanced_edit)
      tr.append($('<th/>').html('&nbsp;'));
    
    $.each(this.fields, function(i, field) {
      if (field.show)
      {
        var s = field.sort ? field.sort : field.name;        
        var arrow = that.pager.options.sort == s ? (parseInt(that.pager.options.desc) == 1 ? ' &uarr;' : ' &darr;') : '';                
        var link = that.pager_hash({
          sort: s,
          desc: (that.pager.options.sort == s ? (parseInt(that.pager.options.desc) == 1 ? '0' : '1') : '0')
        });
                
        //var input = $('<input/>').attr('type', 'checkbox').attr('id', 'quick_edit_' + field.name).val(field.name)            
        //  .change(function() {
        //    that.quick_edit_field = $(this).prop('checked') ? $(this).val() : false;
        //    that.refresh(); 
        //  });
        //if (field.name == that.quick_edit_field)
        //  input.prop('checked', 'true');         
        tr.append($('<th/>')
          //.append(input).append('<br/>')
          .append($('<a/>')
            .attr('id', 'quick_edit_' + field.name).val(field.name)
            .attr('href', link)            
            .data('sort', s)                        
            .html(field.nice_name + arrow)            
          )
        );
      }        
    });
    return tr;
  },
  
  table_row: function(m)
  {
    var that = this;
    
    var tr = $('<tr/>').attr('id', 'model_row_' + m.id); 
      
    if (that.allow_bulk_edit || that.allow_bulk_delete || that.allow_duplicate)
    {
      var checkbox = $('<input/>').attr('type', 'checkbox').attr('id', 'model_' + m.id)        
        .click(function(e) {           
          e.stopPropagation();
          var model_id = $(this).attr('id').replace('model_', '');          
          if (model_id == 'NaN')
            alert("Error: invalid model id.");
          else
          {
            model_id = parseInt(model_id);
            var checked = $(this).prop('checked');
            var i = that.model_ids.indexOf(model_id);                    
            if (checked && i == -1) that.model_ids.push(model_id);
            if (!checked && i > -1) that.model_ids.splice(i, 1);
          }
          $('#' + that.container + '_check_all').prop('checked', that.all_models_selected());      
        });
      if (that.model_ids.indexOf(m.id) > -1)
        checkbox.prop('checked', 'true');  
      tr.append($('<td/>').append(checkbox));
    }
    if (this.allow_advanced_edit)
    {      
      tr.append($('<td/>')
        .addClass('edit_button')
        .mouseover(function() { $(this).addClass('edit_button_over'); })
        .mouseout( function() { $(this).removeClass('edit_button_over'); })
        .click(function(e) { e.stopPropagation(); that.edit_click_handler(m.id, that, e); })
        .append($('<span/>').addClass('ui-icon ui-icon-pencil'))
      );
    }                
    tr.click(function(e) {
      var model_id = $(this).attr('id').replace('model_row_', ''); 
      that.row_click_handler(model_id, that, e);
    });
          
    $.each(that.fields, function(j, field) {
      if (field.show)
      {
        var td = $('<td/>');
        if (field.editable && that.quick_edit_model_id == m.id)
          td.append($('<div/>').attr('id', 'model_' + m.id + '_' + field.name));
        else                        
          td.html(field.text ? field.text(m) : field.value(m));
        tr.append(td);
      }
    });
    return tr;
  },
  
  column_checkboxes: function()
  {
    var that = this;
    var div = $('<div/>').attr('id', that.container + '_columns');
    $.each(this.fields, function(i, field) {
      var input = $('<input/>')
        .attr('type', 'checkbox')
        .attr('id', 'field_' + field.name)
        .click(function(e) {                      
          var field_name = $(this).attr('id').replace('field_', '');          
          var checked = $(this).prop('checked');                    
          $.each(that.fields, function(j, f) {            
            if (f.name == field_name)
            {
              f.show = checked;
              that.print();
            }      
          });               
        });        
      if (field.show)
        input.prop('checked', 'true');      
      
      div.append($('<div/>').addClass('label_with_checkbox')
        .append(input)
        .append($('<label/>').attr('for', 'field_' + field.name).html(field.nice_name))
      );
    });
    return div;
  },

  bulk_edit: function()
  {
    var that = this;
    if (this.model_ids.length == 0)
    {
      $('#message').html("<p class='note error'>Please select at least one row.</p>");
      return;
    }   
    var div = $('<div/>')
      .append($('<h2/>').html('Bulk Edit Jobs'))
      .append($('<p/>').html('Any change you make the fields below will apply to all the selected rows.'));
    $.each(this.fields, function(i, field) {
      if (field.bulk_edit == true)
        div.append($('<p/>').append($('<div/>').attr('id', 'bulkmodel_1_' + field.name)));
    });      
    div.append($('<input/>').attr('type','button').val('Finished').click(function() { $('#message').empty(); }));    
    $('#message').empty().append(div);
        
    var params = this.model_ids.map(function(model_id) { return 'model_ids[]=' + model_id; }).join('&');
    var attribs = [];
    $.each(this.fields, function(i, field) {
      if (field.bulk_edit == true)
      {              
        var attrib = $.extend({}, field);        
        attrib['value'] = '';
        attrib['after_update'] = function() { that.refresh(); };
        attrib['width'] = 600;
        attribs.push(attrib);
      }
    });
    
    m = new ModelBinder({
      name: 'BulkModel',
      id: 1,
      update_url: that.bulk_update_url + '?' + params,
      authenticity_token: this.form_authenticity_token,
      attributes: attribs
    });
  },
  
  bulk_delete: function(confirm)
  {
    var that = this;
    if (this.model_ids.length == 0)
    {
      $('#message').html("<p class='note error'>Please select at least one row.</p>");
      return;
    } 
    if (!confirm)
    {
      var p = $('<p/>').addClass('note').addClass('warning')
        .append('Are you sure you want to delete the selected rows? ')      
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.bulk_delete(true); }))
        .append($('<input/>').attr('type','button').val('No').click(function() { $('#message').empty(); }));
      $('#message').empty().append(p);
      return;
    }        
    var params = this.model_ids.map(function(model_id) { return 'model_ids[]=' + model_id; }).join('&');
    $('#' + this.container).html("<p class='loading'>Refreshing...</p>");
    $.ajax({ 
      url: that.bulk_delete_url,
      type: 'delete',
      data: {
        model_ids: that.model_ids
      },
      success: function(resp) {
        $('#message').empty();
        that.refresh();        
      }      
    });        
  },
  
  model_for_id: function(model_id)
  {
    for (var i=0; i<this.models.length; i++)
      if (this.models[i].id == model_id)
        return this.models[i];
    return false;
  },
  
  duplicate: function(count)
  {
    var that = this;        
    if (this.model_ids.length == 0)
    {
      var p = $('<p/>').addClass('note error').html("Please select a row.");
      $('#message').empty().append(p);
      return;
    }
    if (this.model_ids.length > 1)
    {
      var p = $('<p/>').addClass('note error').html("Please select a single row.");
      $('#message').empty().append(p);
      return;
    }
    if (!count)
    {
      var p = $('<p/>').addClass('note')
        .append('How many times do you want this duplicated?')          
        .append($('<input/>').attr('type', 'text').attr('id', 'count').css('width', '50'))
        .append('<br />')
        .append($('<input/>').attr('type', 'button').val('Cancel').click(function(e) { $('#message').empty(); })).append(' ')
        .append($('<input/>').attr('type', 'button').val('Duplicate').click(function(e) { that.duplicate($('#count').val()); return false; }));
      $('#message').empty().append(p);
      return;      
    }    
    $('#message').html("<p class='loading'>Duplicating...</p>");
    $.ajax({
      url: that.duplicate_url(that.model_ids[0], that),
      type: 'post',
      data: { count: count },
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) { $('#message').empty(); that.refresh(); }
      }
    });    
  },
  
  pager_div: function(summary)
  {
    var that = this;
    var p = this.pager;
    
    // Set default parameter values if not present    
    if (!p.options.items_per_page) p.options.items_per_page = 10  
    if (!p.options.page) 		       p.options.page           = 1   
  		
  	var page = parseInt(p.options.page);
  			
  	// Max links to show (must be odd) 
  	var total_links = 5;
  	var prev_page = page - 1;
  	var next_page = page + 1;
  	var total_pages = Math.ceil(parseFloat(p.options.item_count)/parseFloat(p.options.items_per_page));
  	var start = 1;
  	var stop = 1;
  	
  	if (total_pages < total_links)
  	{
  		start = 1;
  		stop = total_pages;
  	}			
  	else
  	{
  		start = page - Math.floor(total_links/2);			
  		if (start < 1) start = 1; 
  		stop = start + total_links - 1
  		
  		if (stop > total_pages)
  		{
  			stop = total_pages;				
  			start = stop - total_links;  				
  			if (start < 1) start = 1;
  		}
  	}
  	
  	var div = $('<div/>').addClass('pager');
  	if (summary)
  	  div.append($('<p/>').html("Results: showing page " + page + " of " + total_pages));

  	if (total_pages > 1)
  	{
  	  var div2 = $('<div/>').addClass('page_links');
  	  if (page > 1)
  	    div2.append($('<a/>').attr('href', this.pager_hash({ page: prev_page })).html('Previous').click(function(e) { that.hash_click(e, this); }));  	        	      	  
  	  for (i=start; i<=stop; i++)
  	  {
  	  	if (page != i)
  	  	  div2.append($('<a/>').attr('href', this.pager_hash({ page: i })).html(i).click(function(e) { that.hash_click(e, this); }));
  	  	else
  	  	  div2.append($('<span/>').addClass('current_page').html(i));  	  		
  	  }  	  
  	  if (page < total_pages)
  	    div2.append($('<a/>').attr('href', this.pager_hash({ page: next_page })).html('Next').click(function(e) { that.hash_click(e, this); }));
  	  div.append(div2);
  	}
  	return div;
  },
  
  hash_click: function(e, el) {
    e.preventDefault();
    e.stopPropagation();
    window.location.hash = $(el).attr('href').substr(1);
    this.refresh();
  },
  
  pager_params: function(h)
  {
    var that = this;    
    var p = $.extend({}, this.pager.params);
    if (this.pager.options)
    {      
      if (this.pager.options.sort) p.sort = this.pager.options.sort;
      if (this.pager.options.desc) p.desc = this.pager.options.desc ? 1 : 0;
      if (this.pager.options.page) p.page = this.pager.options.page;
    }
    if (h)      
    {
      for (var i in h)
      {        
        //console.log('' + i + ' = ' + h[i]);        
        //console.log(typeof(h[i]));        
        //console.log('-------------------');
        if (typeof(h[i]) == 'boolean')
          p[i] = h[i] ? 1 : 0;
        else
          p[i] = h[i];
      }
    }
    return p;
  },
  
  pager_hash: function(h)
  {                           
    var p = this.pager_params(h);                  
  	var qs = [];
  	$.each(p, function(k,v) { qs.push('' + k + '=' + encodeURIComponent(v)); });
  	return '#' + qs.join('&');  	
  },
  
  /****************************************************************************/
  
  new_model_link: function()
  {
    var that = this;
    return $('<a/>').attr('href', '#').html(that.new_model_text).click(function(e) { e.preventDefault(); that.new_form(); });
  },
  
  new_form: function()
  {
    var that = this;
    if (!$('#' + that.container + '_new_form_container').is(':empty'))
    {
      $('#' + that.container + '_new_form_container').slideUp(function() {          
        $('#' + that.container + '_new_form_container').empty();
      });
      return;
    }      
        
    var form = $('<form/>').attr('id', 'new_form')
      .append($('<input/>').attr('type', 'hidden').attr('name', 'authenticity_token').val(that.form_authenticity_token));
    $.each(this.new_model_fields, function(i, f) {
      form.append($('<p/>').append($('<input/>').attr('type', 'text').attr('name', f.name).attr('placeholder', f.nice_name).css('width', '' + f.width + 'px')));
    });
    form
      .append($('<div/>').attr('id', 'new_message'))
      .append($('<p>')        
        .append($('<input/>').attr('type', 'button').val('Cancel').click(function(e) { $('#' + that.container + '_new_form_container').empty(); }))
        .append(' ')
        .append($('<input/>').attr('type', 'submit').val('Add').click(function(e) { that.add_model(); return false; }))
      );                
    $('#' + that.container + '_new_form_container').hide().empty().append(
      $('<div/>').addClass('note').css('margin-bottom', '10px')
        .append($('<h2/>').css('margin-top', 0).css('padding-top', 0).html(that.new_model_text))
        .append(form)
      ).slideDown();
  },
    
  add_model: function() 
  {
    var that = this;
    $('#new_message').html("<p class='loading'>Adding...</p>");
    $.ajax({
      url: this.add_url,
      type: 'post',
      data: $('#new_form').serialize(),
      success: function(resp) {
        if (resp.error) $('#new_message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.redirect || resp.refresh) that.refresh();
      }
    });
  },
  
  
};
