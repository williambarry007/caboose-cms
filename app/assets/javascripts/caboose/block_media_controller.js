
var BlockMediaController = function(params) { this.init(params); };

BlockMediaController.prototype = {
  
  post_id: false,
  page_id: false,
  block_parent_id: false,
  block_id: false,
  top_cat_id: false,
  cat: false,
  cat_id: false,  
	  
  init: function(params) {
    var that = this;
    for (var i in params)
      this[i] = params[i];                          
    that.refresh();    
  },    
  
  refresh: function()
  {
    var that = this;
    that.refresh_categories(function() {        
      that.refresh_media();
    });
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

  print_media: function() 
  {
    var that = this;
    var ul = $('<ul/>');    
    if (that.cat.media.length > 0)
    {      
      $.each(that.cat.media, function(i, m) {        
        var li = $('<li/>')          
          .attr('id', 'media' + m.id)
          .addClass('media')          
          .data('media_id', m.id)
          .click(function(e) { that.select_media($(this).data('media_id')); })
          .append($('<span/>').addClass('name').html(m.name));
        if (m.image_urls)
          li.append($('<img/>').attr('src', m.image_urls.tiny_url));
        ul.append(li);      
      });
    }
    else
      ul = $('<p/>').html("This category is empty.");
    $('#media').empty().append(ul);                
  },
  
  //============================================================================
        
  select_media: function(media_id)
  {
    var that = this;
    $.ajax({
      url: '/admin/' + (that.page_id ? 'pages/' + that.page_id : 'posts/' + that.post_id) + '/blocks/' + that.block_id,
      type: 'put',
      data: { media_id: media_id },
      success: function(resp) {
        window.location = '/admin/pages/' + that.page_id + '/blocks/' + that.block_parent_id + '/edit';        
      }
    });
  },
  
  select_category: function(cat_id)
  {
    var that = this;
    that.cat_id = cat_id;
    that.print_categories();
    that.refresh_media();        
  }
  
};
