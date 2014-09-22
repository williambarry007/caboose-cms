
var IndexTable = function(params) { this.init(params); }
IndexTable.prototype = {
  
  //============================================================================
  // Required parameters   
  //============================================================================
  
  form_authenticity_token: false,
  
  // Container for the table
  container: 'models',
  
  // Base URL used for default refresh/update/delete/bulk URLs
  base_url: false,
    
  // Where to get model json data  
  refresh_url: false,
  
  // Where to send bulk updates
  bulk_update_url: false,
  
  // Where to send bulk deletes
  bulk_delete_url: false,
    
  // Where to send normal updates  
  // Example: function(model_id) { return '/admin/models/' + model_id; }
  update_url: false,
  
  // Where to send duplicate calls
  // Example: function(model_id) { return '/admin/models/' + model_id + '/duplicate' },
  duplicate_url: false,
  
  // What to do when a row is clicked
  // Example: function (model_id) { return '/admin/models/' + model_id; }
  row_click_handler: false,
  
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
  
  // The post/get in the original request
  post_get: false,
      
  //============================================================================
  // End of required parameters
  //============================================================================
  
  models: [],
  model_ids: [],
  quick_edit_field: false, // The field currently being edited
  refresh_count: 0,

  // Pager fields
  pager_params: {    
    //sort: '',
    //desc: false,
    //item_count: 0,  		
    //items_per_page: 4,
    //page: 1        
  },
  
  init: function(params) {
    for (var thing in params)
      this[thing] = params[thing];    
        
    var that = this;
    if (!this.refresh_url       ) this.refresh_url       = this.base_url + '/json';
    if (!this.bulk_update_url   ) this.bulk_update_url   = this.base_url + '/bulk';    
    if (!this.bulk_delete_url   ) this.bulk_delete_url   = this.base_url + '/bulk';                            
    if (!this.update_url        ) this.update_url        = function(model_id) { return this.base_url + '/' + model_id; };            
    if (!this.duplicate_url     ) this.duplicate_url     = function(model_id) { return this.base_url + '/' + model_id + '/duplicate'; };
    if (!this.row_click_handler ) this.row_click_handler = function(model_id) { window.location = this.base_url + '/' + model_id; };

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
      this.pager_params[i] = b[i];
    
    // If there's a querystring, then redirect to hash
    //if (window.location.search.length > 0)
    //{
    //  //alert('Testing');      
    //  //window.location = this.pager_url({ base_url: window.location.pathname }).replace('?', '#');      
    //}
  },

  refresh: function()
  {    
    this.parse_querystring();
        
    var that = this;
    var $el = $('#columns').length > 0 ? $('#table_container') : $('#'+this.container);
    $el.html("<p class='loading'>Refreshing...</p>");
    $.ajax({ 
      url: that.refresh_url,
      type: 'get',
      data: that.pager_params,
      success: function(resp) {
        for (var thing in resp['pager'])
          that.pager_params[thing] = resp['pager'][thing];        
        that.models = resp['models'];
        $.each(that.models, function(i, m) {
          m.id = parseInt(m.id);                    
        });
        that.print();
        
        // Set the history state
        //var qs = that.pager_querystring();
        //if (that.refresh_count > 0 && qs != window.location.hash)
        //{
        //  if(history.pushState) history.pushState(null, null, '#' + qs);
        //  else                  location.hash = '#' + qs;
        //}
        that.refresh_count += 1;
      },
      error: function() { $('#' + this.container).html("<p class='note error'>Error retrieving data.</p>"); }
    });
  },
  
  print: function()
  {
    var that = this;
    
    var tbody = $('<tbody/>').append(this.table_headers());            
    $.each(that.models, function(i, m) {
      tbody.append(that.table_row(m));
    });                                
    var table = $('<table/>').addClass('data').css('margin-bottom', '10px').append(tbody);
    var pager = this.pager();    
        
    if ($('#columns').length > 0)
    {
      $('#table_container').empty().append(table);
      $('#pager').empty().append(pager);
    }
    else
    {
      var columns = this.column_checkboxes();      
      
      $('#' + that.container).empty()
        .append($('<a/>').attr('href', '#').html('Show/Hide Columns').click(function(e) { e.preventDefault(); $('#columns').slideToggle(); }))          
        .append($('<div/>').attr('id', 'columns').append(columns))
        .append($('<div/>').attr('id', 'table_container').append(table))        
        .append($('<div/>').attr('id', 'pager').append(pager))        
        .append($('<div/>').attr('id', 'message'))
        .append($('<p/>')
          .append($('<input/>').attr('type', 'button').attr('id', 'bulk_edit'  ).val('Bulk Edit'  ).click(function(e) { that.bulk_edit();   })).append(' ')
          .append($('<input/>').attr('type', 'button').attr('id', 'bulk_delete').val('Bulk Delete').click(function(e) { that.bulk_delete(); })).append(' ')
          .append($('<input/>').attr('type', 'button').attr('id', 'duplicate'  ).val('Duplicate'  ).click(function(e) { that.duplicate();   }))
        );
      $('#columns').hide();
    }    
      
    if (that.quick_edit_field)
    {
      $.each(that.models, function(i, m) {
        $.each(that.fields, function(j, field) {
          if (field.show && field.name == that.quick_edit_field)
          {            
            var attrib = $.extend({}, field);
            attrib['value'] = field.value(m);
            attrib['fixed_placeholder'] = false;
            //if (field.text)
            //  attrib['text'] = field.text(m);
            new ModelBinder({
              name: 'Model',
              id: m.id,
              update_url: that.update_url(m.id),
              authenticity_token: that.form_authenticity_token,
              attributes: [attrib]
            });
          }
        });
      });
    }
  },
  
  table_headers: function()
  {
    var that = this;
    var tr = $('<tr/>').append($('<th/>').html('&nbsp;'));
    //var url = this.base_url + this.base_url.indexOf('?') > -1 ? '&' : '?';
    
    $.each(this.fields, function(i, field) {
      if (field.show)
      {
        var arrow = that.pager_params.sort == field.sort ? (parseInt(that.pager_params.desc) == 1 ? ' &uarr;' : ' &darr;') : '';
        //var link = url + "sort=" + field.sort + "&desc=" + (that.pager_params.sort == field.sort ? (parseInt(that.pager_params.desc) == 1 ? '0' : '1') : '0');
        //var link = that.pager_url({
        var link = that.pager_hash({
          sort: field.sort,
          desc: (that.pager_params.sort == field.sort ? (parseInt(that.pager_params.desc) == 1 ? '0' : '1') : '0')
        });
        
        var input = $('<input/>').attr('type', 'checkbox').attr('id', 'quick_edit_' + field.name).val(field.name)            
          .change(function() {
            that.quick_edit_field = $(this).prop('checked') ? $(this).val() : false;
            that.refresh(); 
          });
        if (field.name == that.quick_edit_field)
          input.prop('checked', 'true');         
        tr.append($('<th/>').append(input).append('<br/>')
          .append($('<a/>')
            .attr('href', link)            
            .data('sort', field.sort)                        
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
      });
    if (that.model_ids.indexOf(m.id) > -1)
      checkbox.prop('checked', 'true');      
      
    var tr = $('<tr/>')
      .attr('id', 'model_row_' + m.id)                
      .append($('<td/>').append(checkbox));
    if (!that.quick_edit_field)
    {
      tr.click(function(e) {
        var model_id = $(this).attr('id').replace('model_row_', ''); 
        that.row_click_handler(model_id);
      });
    }
      
    $.each(that.fields, function(j, field) {
      if (field.show)
      {
        var td = $('<td/>');
        if (that.quick_edit_field == field.name)
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
    var div = $('<div/>').attr('id', 'columns');
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
      url: that.duplicate_url(that.model_ids[0]),
      type: 'post',
      data: { count: count },
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) { $('#message').empty(); that.refresh(); }
      }
    });    
  },
  
  pager: function(summary)
  {
    var that = this;
    var pp = this.pager_params;
    
    // Set default parameter values if not present
    if (!pp.items_per_page) pp.items_per_page = 10  
    if (!pp.page) 		      pp.page           = 1   
  		
  	var page = parseInt(pp.page);
  			
  	// Max links to show (must be odd) 
  	var total_links = 5;
  	var prev_page = page - 1;
  	var next_page = page + 1;
  	var total_pages = Math.ceil(parseFloat(pp.item_count)/parseFloat(pp.items_per_page));
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
  	    div2.append($('<a/>').attr('href', this.pager_hash({ page: prev_page })).html('Previous'));  	        	      	  
  	  for (i=start; i<=stop; i++)
  	  {
  	  	if (page != i)
  	  	  div2.append($('<a/>').attr('href', this.pager_hash({ page: i })).html(i));
  	  	else
  	  	  div2.append($('<span/>').addClass('current_page').html(i));  	  		
  	  }  	  
  	  if (page < total_pages)
  	    div2.append($('<a/>').attr('href', this.pager_hash({ page: next_page })).html('Next'));
  	  div.append(div2);
  	}
  	return div;
  },
  
  pager_hash: function(h)
  {
    var that = this;
    var pp = $.extend({}, this.pager_params);
    for (var i in h)
      pp[i] = h[i];
              
  	var qs = [];
  	$.each(pp, function(k,v) {
  	  if (k == 'base_url' || k == 'item_count' || k == 'items_per_page' || k == 'use_url_params')
  	    return;
  	  qs.push('' + k + '=' + encodeURIComponent(v)); 
  	});
  	return '#' + qs.join('&');  	
  }
  
};
