
var MediaController = function(params) { this.init(params); };

MediaController.prototype = {
  
  top_cat_id: false,
  cat: false,
  cat_id: false,
  categories: false,  
  s3_upload_url: false,
	aws_access_key_id: false,		
	policy: false,
	signature: false,
	selected_media: false,
	uploader: false,
  refresh_unprocessed_images: false,	
	  
  
  
  
  
  init: function(params) {
    var that = this;
    for (var i in params)
      this[i] = params[i];
            
    $("#uploader")
      .empty()
      .append($('<p/>')
        .append($('<a/>').attr('href', '#').html('Upload').click(function(e) { e.preventDefault(); that.toggle_uploader(); }))
        .append(' | ')
        .append($('<a/>').attr('href', '#').html('Select All').click(function(e) { e.preventDefault(); that.select_all_media(); }))
      )
      .append($('<div/>').attr('id', 'the_uploader'));          
    that.refresh();    
  },    
  
  refresh: function()
  {
    var that = this;
    that.refresh_categories();
    that.refresh_media();
    that.print_controls();
    
  },
      
  toggle_uploader: function()
  {
    var that = this;
    if (that.uploader)
    {      
      $("#the_uploader").slideUp(400, function() {
        $("#the_uploader").plupload('destroy');
        that.uploader = false;
      });            
    }
    else
    {      
      $("#the_uploader").hide();
      that.uploader = $("#the_uploader").plupload({
		    runtimes: 'html5,flash,silverlight',
		    url: that.s3_upload_url,		      
		    multipart: true,
		    multipart_params: {
		    	key: that.cat_id + '_${filename}', // use filename as a key
		    	Filename: that.cat_id + '_${filename}', // adding this to keep consistency across the runtimes
		    	acl: 'public-read',
		    	//'Content-Type': 'image/jpeg',
		    	AWSAccessKeyId: that.aws_access_key_id,		
		    	policy: that.policy,
		    	signature: that.signature
		    },		
		    file_data_name: 'file', // optional, but better be specified directly
		    filters: {			
		    	max_file_size: '100mb', // Maximum file size			
		    	mime_types: [{ title: "Upload files", extensions: "jpg,jpeg,png,gif,tif,tiff,pdf,doc,docx,odt,odp,ods,ppt,pptx,xls,xlsx,zip,tgz,csv,txt" }] // Specify what files to browse for		    	
		    },		
		    flash_swf_url: '../../js/Moxie.swf', // Flash settings		
		    silverlight_xap_url: '../../js/Moxie.xap', // Silverlight settings
        init: {
          BeforeUpload: function(up, file) {        
            $.ajax({
              url: '/admin/media/pre-upload',
              type: 'post',
              data: {
                media_category_id: that.cat_id,
                name: file.name 
              },
              success: function(resp) {},
              async: false          
            });
            controller.refresh();
          },
          FileUploaded: function(ip, file)
          {
            that.refresh();            
          },          
          UploadComplete: function(up, files) {
            that.refresh();
            if (that.uploader)
            {
              $("#the_uploader").slideUp(400, function() {
                $("#the_uploader").plupload('destroy');
                that.uploader = false;
              });
            }
          }
        }
      });
      $("#the_uploader").slideDown();      
    }
  },
    
  refresh_categories: function(after) 
  {
    var that = this;
    $.ajax({
      url: '/admin/media-categories/tree',
      type: 'get',
      async: false,      
      success: function(resp) { 
        that.top_category = resp;
        if (!that.cat_id)
          that.cat_id = that.top_category.id;
        that.print_categories();
        if (after) after();
      }        
    });
  },
  
  refresh_media: function() 
  {
    var that = this;
    $.ajax({
      url: '/admin/media/json',
      type: 'get',
      async: false,
      data: { media_category_id: that.cat_id },
      success: function(resp) { 
        that.cat = resp;
        that.cat_id = that.cat.id;
        that.selected_media = [];
        that.print_media();
      }        
    });
  },
  
  print_categories_helper: function(cat)
  {
    var that = this;
    var li = $('<li/>')
      .addClass('dd-item')
      .addClass('category')
      .attr('id', 'cat' + cat.id)
      .data('id', cat.id)
      .data('media_category_id', cat.id)
      .append($('<div/>').addClass('dd-handle').html(cat.name + ' (' + cat.media_count + ')'));
    if (cat.children.length > 0)
    {
      var ol = $('<ol/>').addClass('dd-list')
      $.each(cat.children, function(i, cat2) {
        ol.append(that.print_categories_helper(cat2));
      });
      li.append(ol);
    }           
    if (cat.id == that.cat_id)    
      li.addClass('selected');
    return li;        
  },
      
  print_categories: function() 
  {
    var that = this;
    var ol = $('<ol/>').addClass('dd-list');        
    ol.append(that.print_categories_helper(that.top_category));
    $('#categories').empty().append(ol)
      .append($('<p/>').append($('<a/>').attr('href', '#').html('New Category').click(function(e) { e.preventDefault(); that.add_category(); })))
      .append($('<div/>').attr('id', 'new_cat_message'));
    //$('#categories').nestable({
    //
    //});

    $.each(that.categories, function(i, cat) {
      $('#cat' + cat.id).droppable({
        accept: function(draggable) { return (draggable.hasClass('category') || draggable.hasClass('media')) },
        hoverClass: 'cat_hover',
        drop: function(event, ui) {                         
          if (ui.draggable.hasClass('category'))
          {
            var child_cat_id = ui.draggable.data('media_category_id');
            var new_parent_id = $(this).data('media_category_id');                      
            $.ajax({
              url: '/admin/media-categories/' + child_cat_id,
              type: 'put',
              data: { parent_id: new_parent_id },
              success: function(resp) { that.refresh_categories(); }              
            });            
          }
          else // media
          {               
            var media_category_id = $(this).data('media_category_id');
            var ids = (that.selected_media.length > 0 ? that.selected_media : [ui.draggable.data('media_id')]);          
            $.ajax({
              url: '/admin/media-categories/' + media_category_id + '/attach',
              type: 'post',
              data: { media_id: ids },
              success: function(resp) { that.refresh_categories(); that.refresh_media(); }              
            });
          }
        }        
      });                
      $('#cat' + cat.id).draggable({ revert: 'invalid' });
    });    
  },
  
  print_controls: function()
  {
    var that = this;
    $('#controls').empty()
      .append($('<div/>').attr('id', 'delete').append($('<p/>').addClass('delete_dropper').html('Delete')));
      
    $('#delete').droppable({
      accept: function(draggable) { return (draggable.hasClass('category') || draggable.hasClass('media')) },
      hoverClass: 'hover',
      drop: function(event, ui) {        
        if (ui.draggable.hasClass('category'))
        {
          var media_category_id = ui.draggable.data('media_category_id');
          that.delete_category(media_category_id);                      
        }
        else // media
        {                    
          id = ui.draggable.data('media_id');
          if (that.selected_media.length > 0 && that.selected_media.indexOf(id) > -1)            
          {            
            that.select_media(id); // Go ahead and de-select because the select event is about to run            
          }                    
          that.delete_media();
        }
      }        
    });
  },  

  print_media: function() 
  {
    var that = this;
    var ul = $('<ul/>');
    var processing = false;
    if (that.cat.media.length > 0)
    {      
      $.each(that.cat.media, function(i, m) {
        if (m.media_type == 'image' && m.processed == false)
          processing = true
        var li = $('<li/>')          
          .attr('id', 'media' + m.id)
          .addClass('media')          
          .data('media_id', m.id)
          .click(function(e) { that.select_media($(this).data('media_id')); })
          .append($('<span/>').addClass('name').html(m.name).click(function(e) {
            e.stopPropagation();
            that.edit_media_description($(this).parent().data('media_id'));
          }));
        if (m.image_urls)
          li.append($('<img/>').attr('src', m.image_urls.tiny_url));                                      
        if (that.selected_media.indexOf(m.id) > -1)
          li.addClass('selected ui-selected');
        ul.append(li);      
      });
    }
    else
      ul = $('<p/>').html("This category is empty.");
    $('#media').empty().append(ul);
    if (that.refresh_unprocessed_images == true && processing)
      setTimeout(function() { that.refresh(); }, 2000);
    
    $.each(that.cat.media, function(i, m) {
      $('li.media').draggable({
        multiple: true,
        revert: 'invalid',
        start: function() { $(this).data("origPosition", $(this).position()); }
      });
    });    
  },     
  
  //============================================================================
        
  select_media: function(media_id)
  {    
    var that = this;    
    var i = that.selected_media.indexOf(media_id);
    if (i > -1)
    {
      that.selected_media.splice(i, 1);
      $('#media' + media_id).removeClass('selected ui-selected');
    }
    else
    {       
      that.selected_media[that.selected_media.length] = media_id;
      $('#media' + media_id).addClass('selected ui-selected').css('top', '0').css('left', '0');
    }        
    
    
    
    
    
    
    
    
    
    
  },
  
  select_all_media: function()
  {
    var that = this;
    
    // See if they're all selected
    var all_selected = true;
    $.each(that.cat.media, function(i, m) {
      if (that.selected_media.indexOf(m.id) == -1)
      {
        all_selected = false
        return false;
      }
    });
    
    // Now de-select everything
    $('li.media').removeClass('selected ui-selected');
    that.selected_media = [];
    
    // And re-select everything if not everything was previously selected
    if (!all_selected)
    {
      $.each(that.cat.media, function(i, m) {
        $('#media' + m.id).addClass('selected ui-selected');
        that.selected_media[i] = m.id;
      });
    }        
  },
  
  delete_media: function(confirm)
  {        
    var that = this;    
    if (!confirm)
    {            
      $.each(that.selected_media, function(i, id) {     
        $('#media' + id).css('top', '0').css('left', '0');        
      });                                  
      var div = $('<p/>').addClass('note error')
        .append('Are you sure?<br/>')        
        .append($('<input/>').attr('type', 'button').val('Yes').click(function() { that.delete_media(true); })).append(" ")
        .append($('<input/>').attr('type', 'button').val('No' ).click(function() { that.refresh_media(); that.print_controls(); }));
      $('#delete').empty().append(div);
      return;            
    }    
    $('#delete').empty().html("<p class='loading'>Deleting...</p>");
    $.ajax({
      url: '/admin/media/bulk',
      type: 'delete',
      data: { ids: that.selected_media },      
      success: function(resp) { that.refresh_categories(); that.refresh_media(); that.print_controls(); }            
    });    
  },
  
  edit_media_description: function(media_id)
  {
    var that = this;
    caboose_modal_url('/admin/media/' + media_id + '/description');
    
    //var div = $('<div/>').attr('id', 'media_' + media_id + '_description');
    //$('#media').append(div);
    //new ModelBinder({
    //  name: 'Media',
    //  id: media_id,
    //  update_url: '/admin/media/' + media_id,
    //  authenticity_token: that.authenticity_token,
    //  attributes: [
    //    {
    //      name: 'description', nice_name: 'Description', type: 'textarea', value: '', width: 400, height: 100, fixed_placeholder: true,        
    //      after_update: function() { $('#media_' + media_id + '_description_container').remove(); },
    //      after_cancel: function() { $('#media_' + media_id + '_description_container').remove(); }          
    //    }
    //  ]      
    //});
    //var options = {      
    //  iframe: true,
    //  innerWidth: 200,
    //  innerHeight:  50,
    //  scrolling: false,
    //  transition: 'fade',
    //  closeButton: false,
    //  onComplete: caboose_fix_colorbox,
    //  opacity: 0.50       
    //};
    //setTimeout(function() { $('#media_' + media_id + '_description_container').colorbox(options); }, 2000);
  },
  
  //============================================================================
  
  select_category: function(cat_id)
  {
    var that = this;
    that.cat_id = cat_id;
    that.print_categories();
    that.refresh_media();        
  },
  
  add_category: function(name)
  {
    var that = this;
    if (!name)
    {      
      var div = $('<p/>').addClass('note warning')
        .append('New Category Name: ')
        .append($('<input/>').attr('type', 'text').attr('id', 'new_cat_name')).append(" ")
        .append($('<input/>').attr('type', 'button').val('Add').click(function() { that.add_category($('#new_cat_name').val()); })).append(" ")
        .append($('<input/>').attr('type', 'button').val('Cancel').click(function() { $('#new_cat_message').empty(); }));
      $('#new_cat_message').empty().append(div);
      return;
    }
    $('#new_cat_message').empty().html("<p class='loading'>Adding category...</p>");
    $.ajax({
      url: '/admin/media-categories',
      type: 'post',
      data: {
        parent_id: that.cat.id,
        name: name
      },
      success: function(resp) {
        if (resp.error) $('#new_cat_message').empty().html("<p class='note error'>" + resp.error + "</p>");
        if (resp.refresh) that.refresh_categories();
      }    
    });
  },
  
  delete_category: function(cat_id, confirm)
  {
    var that = this;
    if (!confirm)
    {
      var div = $('<p/>').addClass('note warning')
        .append('Are you sure? ')        
        .append($('<input/>').attr('type', 'button').val('Yes').click(function() { that.delete_category(cat_id, true); })).append(" ")
        .append($('<input/>').attr('type', 'button').val('No' ).click(function() { that.refresh_categories(); that.print_controls() }));
      $('#delete').empty().append(div);
      return;
    }
    $('#delete').empty().html("<p class='loading'>Deleting...</p>");              
    $.ajax({
      url: '/admin/media-categories/' + cat_id,
      type: 'delete',      
      success: function(resp) {                  
        that.refresh_categories(function() {                        
          var exists = false;
          $.each(that.categories, function(i, cat) { if (cat.id == cat_id) { exists = true; return false; }});
          if (!exists) 
            that.select_category(that.categories[0].id);
          else            
            that.refresh_media();
          that.print_controls();
        });
      }            
    });    
  },
  
};
