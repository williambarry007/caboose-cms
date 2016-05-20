
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
  
  // When to send bulk import CSV data
  bulk_import_url: false,
  
  // Where to post new models
  add_url: false,
  after_add: 'refresh', // or 'redirect'
  
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

  allow_add: true,
  allow_bulk_edit: true,
  allow_bulk_delete: true,
  allow_bulk_import: true,
  allow_duplicate: true,  
  allow_advanced_edit: true,
  bulk_import_fields: false,  
  no_models_text: "There are no models right now.",
  new_model_text: 'New',
  new_model_fields: [{ name: 'name', nice_name: 'Name', type: 'text', width: 400 }],  
  search_fields: false,
  custom_row_controls: false,
  after_print: false,
  table_class: 'data',
          
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

  add_to_url: function(url, str)
  {
    if (url.indexOf('?') > -1)
    {
      bu = url.split('?');
      return bu.shift() + str + '?' + bu.join('?');
    }
    return url + str;
  },
  
  // Constructor
  init: function(params) {
    for (var thing in params)
      this[thing] = params[thing];    
        
    var that = this;        
    if (!this.refresh_url          ) this.refresh_url     = this.add_to_url(this.base_url, '/json');
    if (!this.bulk_update_url      ) this.bulk_update_url = this.add_to_url(this.base_url, '/bulk');   
    if (!this.bulk_delete_url      ) this.bulk_delete_url = this.add_to_url(this.base_url, '/bulk');
    if (!this.add_url              ) this.add_url = this.base_url;
         
    $.each(this.fields, function(i, f) {
      if (f.editable == null) f.editable = true;
    });
    this.init_local_storage();    
    this.get_visible_columns();    
    
    $(window).on('hashchange', function() { that.refresh(); });        
    this.refresh();
  },
  
  parse_querystring: function()
  {
    var b = {};
    
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
    
    // Redirect to the hash page if we have a querystring
    if (!$.isEmptyObject(b))
    {
      var qs = [];
      for (var i in b)
        qs[qs.length] = '' + i + '=' + b[i];      
      var uri = window.location.pathname + '#' + qs.join('&');
      window.location = uri;
      return;
    };
    
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

  refresh: function(skip_parse_querystring)
  {
    var that = this;
    
    if (!skip_parse_querystring)
    {
      that.pager = { options: { page: 1 }, params: {}};
      that.parse_querystring();
    }
            
    var $el = $('#' + that.container + '_table_container').length > 0 ? $('#' + that.container + '_table_container') : $('#' + that.container);
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
    
    //if (that.models == null || that.models.length == 0)
    //{
    //  $('#' + that.container).empty()
    //    .append($('<p/>').append(that.new_model_link()))
    //    .append($('<div/>').attr('id', that.container + '_new_form_container'))        
    //    .append($('<p/>').append(that.no_models_text));              
    //  return;
    //}

    var model_count = that.models ? that.models.length  : 0;      
    var table = that.no_models_text;
    var pager_div = '';

    if (model_count > 0)
    {
      var tbody = $('<tbody/>').append(this.table_headers());            
      $.each(that.models, function(i, m) {
        tbody.append(that.table_row(m));
      });                                
      table = $('<table/>').addClass(that.table_class).css('margin-bottom', '10px').append(tbody);      
      pager_div = this.pager_div();
    }
        
    if ($('#' + this.container + '_table_container').length > 0)
    {
      $('#' + this.container + '_table_container' ).empty().append(table);
      $('#' + this.container + '_pager'           ).empty().append(pager_div);            
      $('#' + this.container + '_toggle_columns'  ).show();              
      $('#' + this.container + '_bulk_delete'     ).show();
      $('#' + this.container + '_bulk_edit'       ).show();
      $('#' + this.container + '_duplicate'       ).show();      
    }
    else
    {
      var controls = $('<p/>');
      if (this.allow_add         ) controls.append($('<input/>').attr('type', 'button').attr('id', this.container + '_new'            ).val(that.new_model_text     ).click(function(e) { that.new_form();           })).append(' ');                                   
                                   controls.append($('<input/>').attr('type', 'button').attr('id', this.container + '_toggle_columns' ).val('Show/Hide Columns'     ).click(function(e) { that.toggle_columns();     })).append(' ');
      if (this.search_fields     ) controls.append($('<input/>').attr('type', 'button').attr('id', this.container + '_toggle_search'  ).val('Show/Hide Search Form' ).click(function(e) { that.toggle_search_form(); })).append(' ');                                   
      if (this.allow_bulk_edit   ) controls.append($('<input/>').attr('type', 'button').attr('id', this.container + '_bulk_edit'      ).val('Bulk Edit'             ).click(function(e) { that.bulk_edit();          })).append(' ');
      if (this.allow_bulk_import ) controls.append($('<input/>').attr('type', 'button').attr('id', this.container + '_bulk_import'    ).val('Import'                ).click(function(e) { that.bulk_import();        })).append(' ');
      if (this.allow_duplicate   ) controls.append($('<input/>').attr('type', 'button').attr('id', this.container + '_duplicate'      ).val('Duplicate'             ).click(function(e) { that.duplicate();          })).append(' ');
      if (this.allow_bulk_delete ) controls.append($('<input/>').attr('type', 'button').attr('id', this.container + '_bulk_delete'    ).val('Delete'                ).click(function(e) { that.bulk_delete();        })).append(' ');
                          
      var c = $('#' + that.container);
      c.empty();        
      c.append($('<div/>').attr('id', that.container + '_controls').append(controls));
      //if (this.search_fields)
      //  c.append(that.search_form());
      c.append($('<div/>').attr('id', that.container + '_message'));
      c.append($('<div/>').attr('id', that.container + '_table_container').append(table));        
      c.append($('<div/>').attr('id', that.container + '_pager').append(pager_div));
      
      if (model_count == 0)
      {
        $('#' + that.container + '_toggle_columns').hide();
        $('#' + that.container + '_bulk_edit'     ).hide();        
        $('#' + that.container + '_duplicate'     ).hide();
        $('#' + that.container + '_bulk_delete'   ).hide();                
        $('#' + that.container + '_pager'         ).hide();
      }
    }    

    if (model_count > 0 && that.quick_edit_model_id)
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
            update_url: that.update_url(that.quick_edit_model_id, that),
            authenticity_token: that.form_authenticity_token,
            attributes: [attrib]            
          });
        }
      });      
    }
    if (that.after_print) that.after_print();
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
    if (that.highlight_id && that.highlight_id == m.id)
      tr.addClass('highlight');
      
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
    var div = $('<div/>').attr('id', that.container + '_columns').addClass('note');
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
          that.set_visible_column(field_name, checked);
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
  
  init_local_storage: function()
  {    
    if (!localStorage) return;
    var that = this;
    
    var cols = localStorage.getItem(this.container + '_cols');
    if (!cols)
    {
      cols = {};
      $.each(this.fields, function(i, f) { cols[f.name] = f.show; });
      localStorage.setItem(this.container + '_cols', JSON.stringify(cols));      
    } 
  },
  
  get_visible_columns: function()
  {
    if (!localStorage) return;        
    var cols = JSON.parse(localStorage.getItem(this.container + '_cols'));
    $.each(this.fields, function(i, f) { f.show = cols[f.name]; });        
  },
  
  set_visible_column: function(col, checked)
  {
    if (!localStorage) return;
    var that = this;    
    var cols = JSON.parse(localStorage.getItem(this.container + '_cols'));
    cols[col] = checked;
    localStorage.setItem(this.container + '_cols', JSON.stringify(cols));            
  },
    
  toggle_columns: function()
  {
    var that = this;
    var columns = that.column_checkboxes();
    that.show_message(columns, 'toggle_columns');    
  },

  bulk_edit: function()
  {
    var that = this;
    if (this.model_ids.length == 0)
    {      
      that.show_message("<p class='note error'>Please select at least one row.</p>", 'bulk_edit_select_row');
      return;
    }   
    var div = $('<div/>').addClass('note')
      .append($('<h2/>').html('Bulk Edit Jobs'))
      .append($('<p/>').html('Any change you make the fields below will apply to all the selected rows.'));
    $.each(this.fields, function(i, field) {
      if (field.bulk_edit == true)
        div.append($('<p/>').append($('<div/>').attr('id', 'bulkmodel_1_' + field.name)));
    });      
    div.append($('<p/>').append($('<input/>').attr('type','button').val('Finished').click(function() { that.hide_message(); })));    
    that.show_message(div, 'bulk_edit_form');
        
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
      that.show_message("<p class='note error'>Please select at least one row.</p>", 'bulk_delete_select_row');
      return;
    } 
    if (!confirm)
    {
      var p = $('<p/>').addClass('note').addClass('warning')
        .append('Are you sure you want to delete the selected rows? ')      
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.bulk_delete(true); })).append(' ')
        .append($('<input/>').attr('type','button').val('No').click(function() { that.hide_message(); }));
      that.show_message(p, 'bulk_delete_confirm');
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
        that.hide_message();
        that.refresh();        
      }      
    });        
  },
  
  bulk_import: function(data, data_url)
  {
    var that = this;
    if (!data && !data_url)
    {
      var div = $('<div/>').addClass('note')
        .append($('<h2/>').html('Bulk Import'))
        //.append($('<p/>').html("Enter either the URL where CSV data can be downloaded or the CSV data.</p>"))
        //.append($('<p/>')
        //  .append('CSV Data URL').append('<br />')
        //  .append($('<input/>').attr('id', that.container + '_bulk_import_data_url').attr('placeholder', 'CSV Data URL').css('width', '100%'))
        //)
        .append($('<p/>')
          .append('CSV Data').append('<br />')
          .append($('<textarea/>').attr('id', that.container + '_bulk_import_data').attr('placeholder', 'CSV Data').css('width', '100%').css('height', '150px'))
        )
        .append($('<p/>')
          .append($('<input/>').attr('type','button').val('Cancel').click(function() { that.hide_message(); })).append(' ')
          .append($('<input/>').attr('type','button').val('Add').click(function() { that.bulk_import($('#' + that.container + '_bulk_import_data').val(), $('#' + that.container + '_bulk_import_data_url').val()); }))
        );        
      if (that.bulk_import_fields)
        div.append($('<p/>').css('font-size', '75%').html("Format: " + that.bulk_import_fields.join(', ')));
      
      that.show_message(div, 'bulk_import_form');
      return;
    }
    that.show_message("<p class='loading'>Adding...</p>", 'bulk_import_loading');
    $.ajax({
      url: this.bulk_import_url,
      type: 'post',
      data: { 
        csv_data: data,
        csv_data_url: data_url
      },
      success: function(resp) {
        if (resp.error)
          that.show_message("<p class='note error'>" + resp.error + "</p>", 'bulk_import_error');        
        else
        {
          that.show_message("<p class='note success'>Added successfully.</p>", 'bulk_import_success');
          setTimeout(function() { that.hide_message(); }, 3000);
          that.refresh();
        }
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
      that.show_message(p, 'duplicate_select_row');
      return;
    }
    if (this.model_ids.length > 1)
    {
      var p = $('<p/>').addClass('note error').html("Please select a single row.");
      that.show_message(p, 'duplicate_select_single_row');
      return;
    }
    if (!count)
    {
      var p = $('<p/>').addClass('note')
        .append('How many times do you want this duplicated?')          
        .append($('<input/>').attr('type', 'text').attr('id', 'count').css('width', '50'))
        .append('<br />')
        .append($('<input/>').attr('type', 'button').val('Cancel').click(function(e) { that.hide_message(); })).append(' ')
        .append($('<input/>').attr('type', 'button').val('Duplicate').click(function(e) { that.duplicate($('#count').val()); return false; }));
      that.show_message(p, 'duplicate_form');
      return;      
    }    
    that.show_message("<p class='loading'>Duplicating...</p>", 'duplicate_loading');
    $.ajax({
      url: that.duplicate_url(that.model_ids[0], that),
      type: 'post',
      data: { count: count },
      success: function(resp) {
        if (resp.error) that.show_message("<p class='note error'>" + resp.error + "</p>", 'duplicate_error');
        if (resp.success) { that.hide_message(); that.refresh(); }
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
    var skip = this.pager.options && this.pager.options.skip ? this.pager.options.skip : [];    
    var p = {};
    for (var i in this.pager.params) if (skip.indexOf(i) == -1) p[i] = this.pager.params[i];
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
  	$.each(p, function(k,v) {  	  
  	  if (k != '[object Object]') qs.push('' + k + '=' + encodeURIComponent(v)); 
  	});
  	return '#' + qs.join('&');  	
  },
  
  /****************************************************************************/
  
  new_model_link: function()
  {
    var that = this;
    return $('<a/>').attr('href', '#').html(that.new_model_text).click(function(e) { e.preventDefault(); that.new_form(); });
  },
  
  hide_message: function() {
    var that = this;
    $('#' + that.container + '_message').slideUp(function() { $('#' + that.container + '_message').empty().css('margin-bottom', 0); });
    that.current_message = false
  },
  
  current_message: false,
  show_message: function(el, name, after) {
    var that = this;
    if (that.current_message == name)
    {
      $('#' + that.container + '_message').slideUp(function() { $('#' + that.container + '_message').empty().css('margin-bottom', 0); });
      that.current_message = false;
      if (after) after();
      return;
    }
    if (!$('#' + that.container + '_message').is(':empty'))
    {
      $('#' + that.container + '_message').slideUp(function() { 
        $('#' + that.container + '_message').empty().append(el).css('margin-bottom', '10px').slideDown();
        if (after) after();
      });
      that.current_message = name;      
      return;
    }
    else     
    {
      $('#' + that.container + '_message').hide().empty().append(el).css('margin-bottom', '10px').slideDown();
      that.current_message = name;
      if (after) after();
    }
  },
  
  new_form: function()
  {
    var that = this;
    
    $.each(this.new_model_fields, function(i, f) {
      if (f.options_url && !f.options)
      {
        $.ajax({
          url: f.options_url,
          type: 'get',
          success: function(resp) { f.options = resp },
          async: false          
        });
      }
    });        
    
    var form = $('<form/>').attr('id', 'new_form')
      .append($('<input/>').attr('type', 'hidden').attr('name', 'authenticity_token').val(that.form_authenticity_token));
    var focus_field = false;
    $.each(this.new_model_fields, function(i, f) {
      if (f.type == 'hidden')
        form.append($('<input/>').attr('type', 'hidden').attr('name', f.name).val(f.value));
      else if (f.type == 'select')
      {       
        var select = $('<select/>').attr('name', f.name);
        $.each(f.options, function(i, option) {
          var opt = $('<option/>').val(option.value).html(option.text);
          if (f.value && f.value == option.value)
            opt.attr('selected', 'true');
          select.append(opt);
        });
        form.append(select);
      }
      else // text
      {
        form.append($('<p/>').append($('<input/>').attr('type', 'text').attr('id', 'new_form_' + f.name).attr('name', f.name).attr('placeholder', f.nice_name).css('width', '' + f.width + 'px')));
        if (!focus_field)
          focus_field = f.name;
      }
    });
    form.append($('<div/>').attr('id', that.container + '_new_message'));
    form.append($('<p>')        
      .append($('<input/>').attr('type', 'button').val('Cancel').click(function(e) { that.hide_message(); })).append(' ')
      .append($('<input/>').attr('type', 'submit').val('Add').click(function(e) { that.add_model(); return false; }))
    );        
    var div = $('<div/>').addClass('note')
      .append($('<h2/>').css('margin-top', 0).css('padding-top', 0).html(that.new_model_text))
      .append(form);        
    that.show_message(div, null, function() { 
      $('#new_form input[name="' + focus_field + '"]').focus();
      
      $.each(that.new_model_fields, function(i, f) {
        if (f.type == 'date')
        {
          $('#new_form_' + f.name).datetimepicker({
            format: f.date_format ? f.date_format : 'm/d/Y',      
            timepicker: false                        
          });
        }
      });
    });
  },
    
  add_model: function() 
  {
    var that = this;
    $('#' + that.container + '_new_message').html("<p class='loading'>Adding...</p>");
    $.ajax({
      url: this.add_url,
      type: 'post',
      data: $('#new_form').serialize(),
      success: function(resp) {
        if (resp.error) $('#' + that.container + '_new_message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.redirect && that.after_add == 'redirect')          
          window.location = resp.redirect;
        else if (resp.redirect || resp.refresh || resp.success)           
        {                      
          that.hide_message();
          that.refresh();          
        }
      }
    });
  },
  
  //============================================================================
  // Seach Form
  //============================================================================
  
  toggle_search_form: function()
  {    
    var that = this;    
    var form = that.search_form();
    that.show_message(form, 'toggle_search_form');    
  },
  
  search_form: function()
  {
    var that = this;
    
    var pp = that.pager_params();
    var tbody = $('<tbody/>');
    $.each(that.search_fields, function(i, f) {
      var tr = $('<tr/>').append($('<td/>').attr('align', 'right').html(f.nice_name));
      var td = $('<td/>');
      if (f.type == 'text')
      {
        td.append($('<input/>').attr('name', f.name).attr('id', f.name).val(pp[f.name]));
      }
      else if (f.type == 'select')
      {
        var options = false;
        if (!f.options && f.options_url)
        {
          $.ajax({
            url: f.options_url,
            type: 'get',
            success: function(resp) { f.options = resp; },
            async: false
          });
        }
        var select = $('<select/>').attr('name', f.name).attr('id', f.name);
        if (f.empty_option_text)
          select.append($('<option/>').val('').html(f.empty_option_text));
        $.each(f.options, function(j, option) {
          var opt = $('<option/>').val(option.value).html(option.text);
          if (pp[f.name] == option.value)
            opt.attr('selected', true);
          select.append(opt);            
        });
        td.append(select);
      }
      tr.append(td);
      tbody.append(tr);
    });    
    var form = $('<form/>')
      .attr('id', 'search_form')
      .append($('<table/>').append(tbody))
      .append($('<p/>').append($('<input/>').attr('type', 'submit').val('Search').click(function(e) { e.preventDefault(); that.search(); })));
    return form;
  },
  
  populate_search_form: function()
  {    
    var pp = this.pager_params();    
    $.each(this.search_form_fields, function(i, f) {      
      $('#' + f).val(pp[f]);
    });      
  },
  
  search: function()
  {
    var that = this;
    $.each(that.search_fields, function(i, f) {      
      that.pager.params[f.name] = $('#'+f.name).val();
    });
    window.location.hash = that.pager_hash();
    that.refresh(true);
  }      
};
