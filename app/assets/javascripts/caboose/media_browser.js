
var MediaBrowser = function(params) { this.init(params); };

MediaBrowser.prototype = {
       
  media_id: false,  
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
  upload_extensions: "jpg,jpeg,png,gif,tif,tiff,pdf,doc,docx,odt,odp,ods,ppt,pptx,xls,xlsx,zip,tgz,csv,txt",
  file_view: 'thumbnail',    
	  
  init: function(params) {
    var that = this;
    for (var i in params)
      this[i] = params[i];
    
    $("#uploader")
      .empty()      
      .append($('<div/>').attr('id', 'the_uploader'));      
    that.refresh();    
  },    
  
  refresh: function()
  {
    var that = this;        
    that.refresh_categories(function() {        
      that.refresh_media();
    });
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
		    	mime_types: [{ title: "Upload files", extensions: that.upload_extensions }] // Specify what files to browse for		    	
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
      url: '/admin/media-categories/flat-tree',
      type: 'get',
      async: false,      
      success: function(resp) { 
        that.categories = resp;
        if (!that.cat_id)
          that.cat_id = that.categories[0].id;
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
    
  print_categories: function() 
  {
    var that = this;
    var ul = $('<ul/>');
    if (that.categories.length > 0)
    {      
      $.each(that.categories, function(i, cat) {        
        var li = $('<li/>')
          .addClass('category')
          .attr('id', 'cat' + cat.id)
          .data('media_category_id', cat.id)
          .append($('<a/>').attr('href', '#').html(cat.name + ' (' + cat.media_count + ')').click(function(e) { e.preventDefault(); that.select_category($(this).parent().data('media_category_id')); }));
        if (cat.id == that.cat_id)
          li.addClass('selected');
        ul.append(li);
      });      
    }
    else
      ul = $('<p/>').html("There are no media categories.");
    $('#categories').empty().append(ul);              
  },
  
  print_controls: function()
  {
    var that = this;
    $('#controls').empty()
      //.append($('<p/>').append($('<a/>').attr('href', '#').html('New Category').click(function(e) { e.preventDefault(); that.add_category(); })))
      //.append($('<div/>').attr('id', 'new_cat_message'))
      //.append($('<p/>').append($('<a/>').attr('href', '#').html('Upload').click(function(e) { e.preventDefault(); that.toggle_uploader(); })))
      //.append($('<p/>').append($('<a/>').attr('href', '#').html('Toggle Thumbnail/List View').click(function(e) { e.preventDefault(); that.toggle_file_view(); })));
      .append($('<p/>')
        .append($('<a/>').attr('href', '#').html('New Category').click(function(e) { e.preventDefault(); that.add_category();    })).append(' | ')              
        .append($('<a/>').attr('href', '#').html('Upload to this Category'      ).click(function(e) { e.preventDefault(); that.toggle_uploader(); })).append(' | ')
        .append($('<a/>').attr('href', '#').html(that.file_view == 'thumbnail' ? 'List View' : 'Thumbnail View').click(function(e) { e.preventDefault(); that.toggle_file_view();     }))
      )
      .append($('<div/>').attr('id', 'new_cat_message'));      
  },

  print_media: function() 
  {
    var that = this;
    var ul = $('<ul/>').addClass(that.file_view + '_view');    
    var processing = false;
    var d = new Date();
    d = d.getTime();
        
    if (that.cat.media.length > 0)
    {      
      $.each(that.cat.media, function(i, m) {
        if (m.media_type == 'image' && m.processed == false)
          processing = true
        var li = $('<li/>')          
          .attr('id', 'media' + m.id)
          .addClass('media')          
          .data('media_id', m.id)
          .click(function(e) { that.select_media(that, $(this).data('media_id')); })
          .append($('<span/>').addClass('name').html(m.original_name));
        if (m.image_urls)
          li.append($('<img/>').attr('src', m.image_urls.tiny_url + '?' + d));
        //if (that.selected_media.indexOf(m.id) > -1)
        //  li.addClass('selected ui-selected');
        if (m.id == that.media_id)
          li.addClass('selected ui-selected');
        ul.append(li);      
      });
    }
    else
      ul = $('<p/>').html("This category is empty.");
    $('#media').empty().append(ul);
    if (that.refresh_unprocessed_images == true && processing)
      setTimeout(function() { that.refresh(); }, 2000);
    if (modal)
      modal.autosize();
    
    $.each(that.cat.media, function(i, m) {
      $('li.media').draggable({
        multiple: true,
        revert: 'invalid',
        start: function() { $(this).data("origPosition", $(this).position()); }
      });
    });
  },
  
  //============================================================================
        
  select_media: function(browser, media_id) {},
             
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
      if (!$('#new_cat_message').is(':empty'))
      {
        $('#new_cat_message').empty();
        return;
      }
      var div = $('<p/>').addClass('note warning')
        .append('Name: ')
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
        if (resp.refresh) { that.cat_id = resp.new_id; that.refresh(); }
      }    
    });
  },

  toggle_file_view: function()
  {
    var that = this;
    that.file_view = (that.file_view == 'thumbnail' ? 'list' : 'thumbnail');
    that.print_controls();
    that.print_media();        
  },  
  
};
