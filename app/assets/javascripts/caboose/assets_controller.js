
var AssetsController = Class.extend({

  manifest: false,
  editable_extensions: ['css', 'js', 'scss'],
  
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];
    that.refresh_manifest(function() { that.print(); });
    
    var h = $(window).outerHeight() - 52; 
    $('#manifest').css('height', '' + h + 'px').css('max-height', '' + h + 'px');    
  },
  
  refresh_manifest: function(after)
  {
    var that = this;
    $.ajax({
      url: '/admin/assets/manifest',
      type: 'get',
      success: function(resp) {
        that.manifest = resp;
        if (after) after();
      }        
    });        
  },
  
  print: function()
  {
    var that = this;
    that.print_manifest();
  },
  
  print_manifest: function()
  {
    var that = this;
    var ul = $('<ul/>');                
    $.each(sorted_hash(that.manifest), function(name, h) {      
      ul.append(that.print_manifest_helper(name, h, ''));
    });
    $('#manifest').empty().append(ul);    
  },
  
  print_manifest_helper: function(name, h, path) 
  {
    var that = this;
    var li = $('<li/>');
    var a = $('<a/>').attr('href', '#').data('path', path + '/' + name).html(name);
    if (typeof h == 'object')
    {
      a.click(function(e) { 
        e.preventDefault();
        var ul = $(this).parent().find('ul:first');
        if (ul.is(':visible'))
          ul.slideUp();
        else
          ul.slideDown();         
      });
    }
    else    
      a.click(function(e) { e.preventDefault(); that.edit_file($(this).data('path')); });
    li.append(a);
        
    if (typeof h == 'object')
    {            
      var ul2 = $('<ul/>').css('display', 'none');
      $.each(sorted_hash(h), function(name2, h2) {
        ul2.append(that.print_manifest_helper(name2, h2, path + '/' + name));
      });
      li.append(ul2);
    }
    return li;
  },
  
  edit_file: function(path)
  {
    var that = this;
    var ext = path.split('.').pop();
        
    if (that.editable_extensions.indexOf(ext) == -1)
    {
      $('#editor').html("<p class='note error'>That type of file is not editable.</p>");
      return;
    }
    $('#editor').html("<p class='loading'>Getting file...</p>");
    
    var str = false;
    var error = false;
    $.ajax({
      url: that.assets_path + path,
      type: 'get',
      success: function(resp) { str = resp; },
      error: function(e) { error = "Error retrieving file." },
      async: false        
    });
    if (error)
    {
      $('#editor').empty().html("<p class='note error'>" + error + "</p>");
      return;
    }
    var w = $(window).outerWidth() - 380;
    var h = $(window).outerHeight() - 200; 
    $('#editor').empty()
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').val('Save'   ).data('path', path).click(function(e) { that.save_file($(this).data('path')); })).append(' ')
        .append($('<input/>').attr('type', 'button').val('Cancel' ).click(function(e) { $('#editor').empty(); }))
      )
      .append($('<div/>').attr('id', 'the_editor').append(str));
      //.append($('<textarea/>').attr('id', 'the_editor')
      //  .css('width', '' + w + 'px')
      //  .css('height', '' + h + 'px')        
      //  .append(str)
      //);
        
    //var editor = ace.edit("the_editor");
    //editor.setTheme("ace/theme/monokai");
    //editor.getSession().setMode("ace/mode/javascript");
  },
  
  save_file: function(path)
  {
    $('#editor').html("<p class='note error'>Saving file...</p>");
    $.ajax({
      url: '/admin/assets' + path,      
      type: 'put',
      data: { 
        path: path, 
        value: $('#the_editor').val() 
      },
      success: function(resp) {
        if (resp.error  ) $('#editor').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.success) $('#editor').html("<p class='note success'>The file was saved successfully.</p>");              
      }                    
    });    
  }
    
});

function sorted_hash(h)
{
  var keys = [];
  for (var k in h)
    if (h.hasOwnProperty(k))
      keys.push(k);        
  keys.sort();
  
  var h2 = {};
  for (i in keys)
  {
    var k = keys[i];
    h2[k] = h[k];
  }
  return h2;  
}
