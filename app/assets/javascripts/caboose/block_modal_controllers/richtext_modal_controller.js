
var RichtextModalController = BlockModalController.extend({
    
  tinymce_initialized: false,
  modal_width: 820,
  modal_height: 500,
  trapFocus: false,

  assets_to_include: function()
  {
    return [
      '//cdn.tinymce.com/4/tinymce.min.js'
      //'//tinymce.cachefly.net/4.0/tinymce.min.js',
      //'caboose/tinymce_init.js'
    ]
  },
  
  print_content: function()
  {
    var that = this;
    
    $(document).bind('cbox_cleanup', function(){
      if (tinymce.get('block_' + that.block_id + '_value'))    
        tinymce.EditorManager.execCommand('mceRemoveEditor', true, 'block_' + that.block_id + '_value');       
    });
        
    var exists = true;
    try { exists = tinymce && tinymce != null; } catch(err) { exists = false; }    
    if (!exists)
    {
      $('#modal_content').html("<p class='loading'>Loading...</p>");
      setTimeout(function() { that.print_content(); }, 100)
      return;
    }
    that.init_tinymce();        
    //if (tinymce.get('block_' + that.block_id + '_value'))    
    //  tinymce.EditorManager.execCommand('mceRemoveEditor', true, 'block_' + that.block_id + '_value');
        
    $('#modal_content').empty().append($('<div/>').attr('id', 'block_' + that.block_id + '_value'));      
    $(document).ready(function() {  
      m = new ModelBinder({
        name: 'Block',
        id: that.block.id,
        update_url: that.block_url(),
        authenticity_token: that.authenticity_token,
        attributes: [{ 
          name: 'value',
          nice_name: 'Content',
          type: 'richtext',
          value: that.block.value,
          width: 800,
          height: 300,
          fixed_placeholder: false,
          after_update: function() {            
            tinymce.EditorManager.execCommand('mceRemoveEditor', true, 'block_' + that.block_id + '_value');
            that.parent_controller.render_blocks();
            that.close(); 
          },
          after_cancel: function() { that.parent_controller.render_blocks(); that.close(); }
        }]
      });
    });
    that.autosize();        
  },
  
  before_crumbtrail_click: function() { var that = this; tinymce.EditorManager.execCommand('mceRemoveEditor', true, 'block_' + that.block_id + '_value'); },  
  before_close:            function() { var that = this; tinymce.EditorManager.execCommand('mceRemoveEditor', true, 'block_' + that.block_id + '_value'); },  
  before_print_advanced:   function() { var that = this; tinymce.EditorManager.execCommand('mceRemoveEditor', true, 'block_' + that.block_id + '_value'); },
  
  init_tinymce: function(force)
  {
    var that = this;
    if (force || that.parent_controller.tinymce_initialized == undefined)      
    {
      tinymce.init({
        selector: 'textarea.tinymce',
        width: '800px',
        height: '300px',
        convert_urls: false,
        plugins: 'advlist autolink lists link image charmap print preview hr anchor pagebreak searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking table contextmenu directionality emoticons template paste textcolor caboose',
        toolbar1: 'caboose_save caboose_cancel | bold italic forecolor backcolor | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image',
        image_advtab: true,
        external_plugins: { 'caboose': '//d9hjv462jiw15.cloudfront.net/assets/tinymce/plugins/caboose/plugin.js' },
        setup: function(editor) {
          var control = ModelBinder.tinymce_control(editor.id);     
          editor.on('keyup', function(e) { control.tinymce_change(editor); });
        }        
      });
      that.parent_controller.tinymce_initialized = true;
    }
  }  
});
