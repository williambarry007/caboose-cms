
var ImagesController = function(params) { this.init(params); };

ImagesController.prototype = {
  
  cat_id: false,
  cat: false,
  
  init: function(params) {
    var that = this;
    for (var i in params)
      this[i] = params[i];
    
    $('#new_cat_link').click(function(e) {
      e.preventDefault();
      that.add_category(that.cat_id);
    });
    
    this.print_images();
  },

  // Gets updated image info from server and prints out categories and images.
  print_images: function() {
    var that = this;
    $('#message').html("<p class='loading'>Refreshing images...</p>");
    $.ajax({
      url: '/admin/images/json',
      type: 'get',
      async: false,
      data: { media_category_id: this.cat_id },
      success: function(resp) {
        that.cat = resp;        
      }        
    });        
    $('#message').empty();
    var ul = $('#media');
    if (this.cat.children.length > 0 || this.cat.images.count > 0)
    {
      $.each(this.cat.children, function(i, cat2) {
        ul.append($('<li/>').addClass('category').attr('id', 'cat' + cat2.id)
          .append($('<a/>').attr('href', '/admin/images?media_category_id=' + cat2.id)
            .append($('<span/>').addClass('icon icon-folder2'))
            .append($('<span/>').addClass('name').html(cat2.name))
          )
        );
      });
      $.each(this.cat.images, function(i, mi) {      
        ul.append($('<li/>').addClass('image').attr('id', 'image' + mi.id)
          .append($('<a/>').attr('href', '/admin/images/' + mi.id)
            .css('background-image', mi.tiny_url)
            .append($('<span/>').addClass('name').html(mi.name))
          )
        );
      });
    }
    ul.replaceWith($('<p/>').html("This category is empty."));
  },
  
  // Adds a new media category  
  add_category: function(parent_id, name)
  {
    var that = this;
    if (!name)
    {
      var div = $('<p/>').addClass('note warning')
        .append('New Category Name: ')
        .append($('<input/>').attr('type', 'text').attr('id', 'new_cat_name')).append(" ")
        .append($('<input/>').attr('type', 'button').val('Add').click(function() { that.add_category(parent_id, $('#new_cat_name').val()); })).append(" ")
        .append($('<input/>').attr('type', 'button').val('Cancel').click(function() { $('#new_cat_message').empty(); }));
      $('#new_cat_message').empty().append(div);
      return;
    }
    $('#new_cat_message').empty().html("<p class='loading'>Adding category...</p>");
    $.ajax({
      url: '/admin/media-categories',
      type: 'post',
      data: {
        parent_id: parent_id,
        name: name
      },
      success: function(resp) {
        if (resp.error) $('#new_cat_message').empty().html("<p class='note error'>" + resp.error + "</p>");
        if (resp.refresh) window.location.reload(true);
      }    
    });
  },

  // Lets a single image poll the server to see if it has been processed.
  wait_for_image_processing: function(image_id, i)
  {
    if (!i) i = 1;
    var is_finished = false;
    $.ajax({
      url: '/admin/images/' + image_id + '/finished',
      type: 'get',
      async: false,
      success: function(resp) {        
        if (resp.error) alert("Error processing image: \n" + resp.error);
        if (resp.is_finished) 
        {
          is_finished = true;
          $('#image' + mi.id + ' a').css('background-image', resp.tiny_url);                  
        }
      }
    });
    if (!is_finished)
      setTimeout(function() { that.wait_for_image_processing(image_id, i+1); }, 500);  
  },

  upload_form: function()
  {
    var that = this;
    $('#file').fileupload({
      //forceIframeTransport: true,    
      autoUpload: true,        
      //replaceFileInput: true,
      //singleFileUploads: false,        
      add: function(e, data) {            
        $.ajax({
          url: '/admin/images/s3',
          type: 'get',
          data: {
            name: data.files[0].name,
            media_category_id: that.cat_id
          },
          async: false,
          success: function(resp) {
            image_ids.push(resp.media_image_id);
            var form = $('#new_image_form');          
            for (var i in resp.fields)            
              form.find("input[name=" + i + "]").val(resp.fields[i]);
            form.attr('action', resp.url);
          }
        });            
        data.submit();
      },                
      progressall: function (e, data) {
        $('#bar').css('width', parseInt(data.loaded / data.total * 100, 10) + '%') 
      },
      start: function (e) {
        $('#file').hide();
        $('#bar').css('background', 'green').css('display', 'block').css('width', '0%').html("&nbsp;"); 
      },
      done: function(e, data) {
        console.log("Upload done.");
        console.log(data);
        setTimeout(function() {
          $.each(image_ids, function(i, id) {
            $.ajax({
              url: '/admin/images/' + id + '/process',
              type: 'get',            
              async: false,
              success: function(resp) {}
            });                                                       
          });
          $('#progress').empty().html("<p class='loading'>Upload complete. Processing images...</p>");
          that.wait_for_image_processing(id);
          
        }, 500);      
      },
      fail: function(e, data) {
        console.log("Upload failed.");
        console.log(data);      
        $('#bar').css("background", "red").text("Failed"); 
      }
    });
  }
};
