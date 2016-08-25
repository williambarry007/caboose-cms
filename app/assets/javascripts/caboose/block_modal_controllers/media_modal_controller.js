
var MediaModalController = DefaultBlockModalController.extend({
    
  media_id: false,
  top_cat_id: false,
  cat_id: false,
  cat: false,
  categories: false,  
  s3_upload_url: false,		      		  	
	aws_access_key_id: false,		
	policy: false,
	signature: false,
	refresh_unprocessed_images: false,		               
	selected_media: false,
	uploader: false,  
  upload_extensions: "jpg,jpeg,png,gif,tif,tiff,pdf,doc,docx,odt,odp,ods,ppt,pptx,xls,xlsx,zip,tgz,csv,txt",
  file_view: 'thumbnail',
  
  assets_to_include: function()
  {
    return [      
      //'plupload/plupload.full.min.js', 
      //'plupload/jquery.ui.plupload/jquery.ui.plupload.js',
      'plupload/plupload_with_jquery.min.js',
      'plupload/jquery.ui.plupload/css/jquery.ui.plupload.css'
    ];   
  },
  
  refresh: function(callback)
  {
    var that = this;
    that.refresh_block(function() {        
      that.refresh_categories(function() {                         
        that.refresh_media(function() {
          that.refresh_policy(function() {
            that.print();
          });
        });
      });
    })
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
        if (!that.cat_id) that.cat_id = that.top_category.id;
        if (after) after();
      }        
    });
  },
  
  refresh_media: function(after) 
  {
    var that = this;    
    $.ajax({
      url: '/admin/media/json',
      type: 'get',
      async: false,
      data: { media_category_id: that.cat_id },
      success: function(resp) {
        that.media = resp;        
        that.selected_media = [];        
        if (after) after();
      }        
    });
  },
    
  refresh_policy: function(after)
  {
    var that = this;
    $.ajax({
      url: '/admin/media/policy',
      type: 'get',
      success: function(resp) {        
        that.policy             = resp.policy;      
        that.signature          = resp.signature;      
        that.s3_upload_url      = resp.s3_upload_url;
        that.aws_access_key_id  = resp.aws_access_key_id;
        that.top_media_category = resp.top_media_category;
        that.top_cat_id         = resp.top_media_category.id;                
        if (after) after();
      }
    });
  },
  
  print_content: function()
  {
    var that = this;    
    $('#modal_content').empty()    
      .append($('<div/>').attr('id', 'top_controls' ))        
      .append($('<div/>').attr('id', 'media'        ));    
    that.print_top_controls();    
    that.print_media();
    that.autosize();
  },
  
  print_top_controls: function() 
  {
    var that = this;
    
    var select = $('<select/>').attr('id', 'categories').change(function(e) {             
      that.select_category($(this).val()); 
    });   
    that.print_categories_helper(that.top_category, select, '');
    
    var div = $('<div/>').attr('id', 'top_controls')
      .append($('<p/>')
        .append(select).append(' | ')
        .append($('<a/>').attr('href', '#').html('New Category'                                                 ).click(function(e) { e.preventDefault(); that.add_category();     })).append(' | ')              
        .append($('<a/>').attr('href', '#').html('Upload to this Category'                                      ).click(function(e) { e.preventDefault(); that.toggle_uploader();  })).append(' | ')
        .append($('<a/>').attr('href', '#').html(that.file_view == 'thumbnail' ? 'List View' : 'Thumbnail View' ).click(function(e) { e.preventDefault(); that.toggle_file_view(); }))
      )
      .append($('<div/>').attr('id', 'new_cat_message'))              
      .append($('<div/>').attr('id', 'uploader'   ).append($('<div/>').attr('id', 'the_uploader')));     
            
    $('#top_controls').replaceWith(div);              
  },
  
  print_categories_helper: function(cat, select, prefix) 
  {
    var that = this;
    var opt = $('<option/>')
      .data('media_category_id', cat.id)
      .val(cat.id)
      .append(prefix + cat.name + ' (' + cat.media_count + ')');      
    if (cat.id == that.cat_id)
      opt.attr('selected', 'true');
    select.append(opt);        
    if (cat.children.length > 0)
    {
      $.each(cat.children, function(i, cat2) {
        that.print_categories_helper(cat2, select, prefix + ' - ');
      });      
    }    
  },

  print_media: function() 
  {
    var that = this;
    var ul = $('<ul/>').addClass(that.file_view + '_view');    
    var processing = false;
    var d = new Date();
    d = d.getTime();
        
    if (that.media.length > 0)
    {      
      $.each(that.media, function(i, m) {
        if (m.media_type == 'image' && m.processed == false)
          processing = true
        var li = $('<li/>')          
          .attr('id', 'media' + m.id)
          .addClass('media')          
          .data('media_id', m.id)
          .click(function(e) { that.print_media_detail($(this).data('media_id')); })
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
    that.autosize();
          
    $.each(that.media, function(i, m) {
      $('li.media').draggable({
        multiple: true,
        revert: 'invalid',
        start: function() { $(this).data("origPosition", $(this).position()); }
      });
    });
  },
  
  print_media_detail: function(media_id)
  {
    var that = this;            
    var m = that.media_with_id(media_id);
         
    var image_urls = $('<div/>').attr('id', 'image_urls').css('margin-bottom', '20px');
    for (var size in m.image_urls)
    {
      var s = size.replace('_url', '');
      s = s[0].toUpperCase() + s.slice(1);
      var url = m.image_urls[size];
      image_urls.append($('<div/>')
        .append($('<span/>').addClass('size').append(s))
        .append($('<input/>').attr('type', 'text').attr('id', 'size_' + s).addClass('url').val(url))
        .append($('<button/>').addClass('clippy').data('clipboard-target', '#size_' + s).append('Copy'))                
      );                        
    }    
    
    $('#top_controls').empty();
    $('#media').empty()              
      .append($('<img/>').attr('id', 'detail_image').attr('src', m.image_urls.thumb_url))      
      .append($('<p/>').append($('<div/>').attr('id', 'media_' + media_id + '_media_category_id' ))) 
      .append($('<p/>').append($('<div/>').attr('id', 'media_' + media_id + '_name'              )))
      .append($('<p/>').append($('<div/>').attr('id', 'media_' + media_id + '_description'       )))
      .append($('<h2/>').append('Image URLs'))
      .append(image_urls);
    $('#modal_controls').empty()
      .append($('<p/>').css('clear', 'both')
        .append($('<input/>').attr('type', 'button').val('< Back'            ).click(function(e) { 
          that.print_top_controls();
          that.print_media();
          that.print_controls();
        }))
        .append($('<input/>').attr('type', 'button').val('Select this Image' ).click(function(e) { that.select_media(media_id)                           }))        
        .append($('<input/>').attr('type', 'button').val('Close'             ).click(function(e) { that.parent_controller.render_blocks(); that.close(); }))
      );
    
    var m = new ModelBinder({
      name: 'Media',
      id: m.id,
      update_url: '/admin/media/' + m.id,      
      authenticity_token: that.authenticity_token,
      attributes: [                                                                                                                                             
        { name: 'media_category_id' , nice_name: 'Category'    , type: 'select' , value: m.media_category_id  , fixed_placeholder: true, width: 400, after_update: function() { m.media_category_id = this.value; }, on_load: function() { that.autosize(); }, options_url: '/admin/media-categories/options' },
        { name: 'name'              , nice_name: 'Name'        , type: 'text'   , value: m.name               , fixed_placeholder: true, width: 400, after_update: function() { m.name              = this.value; }, on_load: function() { that.autosize(); }},
        { name: 'description'       , nice_name: 'Description' , type: 'text'   , value: m.description        , fixed_placeholder: true, width: 400, after_update: function() { m.description       = this.value; }, on_load: function() { that.autosize(); }},        
      ]
    });
    $('#media_' + media_id + '_media_category_id' + '_container').css('width', '400px');
    $('#media_' + media_id + '_name'              + '_container').css('width', '400px');
    $('#media_' + media_id + '_description'       + '_container').css('width', '400px');
       
    $('#image_urls span.size'       ).css('width', '70px').css('display', 'inline-block');
    $('#image_urls input.url'       ).css('width', '270px').css('border', '#ccc 1px solid');
    $('#image_urls button').css('width', '60px');
    
    //c = new Clipboard('.clippy');
    //c.on('success', function(e) {
    //  console.info('Action:', e.action);
    //  console.info('Text:', e.text);
    //  console.info('Trigger:', e.trigger);
    //  e.clearSelection();
    //});
    //c.on('error', function(e) {
    //  console.error('Action:', e.action);
    //  console.error('Trigger:', e.trigger);
    //});
           
    that.autosize();
  },
 
  //============================================================================
  
  toggle_uploader: function()
  {
    var that = this;
    if (that.uploader)
    {      
      $("#the_uploader").slideUp(400, function() {
        $("#the_uploader").plupload('destroy');
        that.uploader = false;
        that.autosize();
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
            that.refresh_media(function() { that.refresh_categories(function() { that.print(); }); });
          },   
          FileUploaded: function(ip, file)
          {
            that.refresh_media(function() { that.refresh_categories(function() { that.print(); }); });            
          },          
          UploadComplete: function(up, files) {
            that.refresh_media(function() { that.refresh_categories(function() { that.print(); }); });
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
      $("#the_uploader").slideDown(400, function() { that.autosize(); });      
    }
  },
  
  //============================================================================
        
  select_media: function(media_id)
  {
    var that = this;    
    $.ajax({
      url: that.block_url(),
      type: 'put',
      data: { media_id: media_id },
      success: function(resp) {
        that.parent_controller.render_blocks();
        that.parent_controller.edit_block(that.block.parent_id);        
      }
    });        
  },         
  
  //============================================================================
  
  select_category: function(cat_id)
  {      
    var that = this;
    that.cat_id = cat_id;
    that.print_top_controls();
    that.refresh_media(function() { that.print_media(); });        
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
        parent_id: that.cat_id,
        name: name
      },
      success: function(resp) {
        if (resp.error) $('#new_cat_message').empty().html("<p class='note error'>" + resp.error + "</p>");
        if (resp.refresh) {
          that.cat_id = resp.new_id;
          that.refresh(function() {
            that.refresh_categories(function() {                         
              that.refresh_media(function() {
                that.refresh_policy(function() {
                  that.print();
                });
              });
            });
          });
        }
      }    
    });
  },

  toggle_file_view: function()
  {
    var that = this;
    that.file_view = (that.file_view == 'thumbnail' ? 'list' : 'thumbnail');    
    that.print_media();        
  },  
  
  media_with_id: function(media_id)
  {
    var that = this;
    var media = false;
    $.each(that.media, function(i, m) {
      if (m.id == media_id)
      {
        media = m;
        return false;
      }
    });
    return media;    
  },    

});
