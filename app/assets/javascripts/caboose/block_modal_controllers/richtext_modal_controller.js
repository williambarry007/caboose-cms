
var RichtextModalController = BlockModalController.extend({
    
  tinymce_initialized: false,
  modal_width: 820,
  modal_height: 500,
  trapFocus: false,

  modal: function(el, width, height, callback)
  {
    var that = this;
    if (!width) width = that.modal_width ? that.modal_width : 400;
    if (!height) height = that.modal_height ? that.modal_height : $(el).outerHeight(true);
    that.modal_element = el;    
    el.attr('id', 'the_modal').addClass('modal').addClass('colorbox').css('width', '' + width + 'px');
    var options = {
      html: el,           
      initialWidth: width, 
      innerWidth: width, 
      scrolling: false,        
      closeButton: false,
      opacity: 0.50,
      onComplete: function() {                
        $("#cboxClose").hide();
        if (callback) callback();        
      }
    };
    if (that.trapFocus === false)
      options['trapFocus'] = false;    
    $.colorbox(options);
  },
  
  last_size: 0,
  autosize: function(msg, msg_container, flag)
  {    
    var that = this;
    if (!flag)
      that.last_size = 0;
    if (!that.modal_element) return;
    if (msg) $('#' + (msg_container ? msg_container : 'modal_message')).html(msg);    
    var h = that.modal_height ? that.modal_height : $(that.modal_element).outerHeight(true) + 20;    
    if (h > 0 && h > that.last_size)    
      $.colorbox.resize({ innerHeight: '' + h + 'px' });
    that.last_size = h;
    
    if (!flag || flag < 2)
      setTimeout(function() { that.autosize(false, false, flag ? flag + 1 : 1); }, 200);
  },
  
  before_close: false,
  close: function()
  {
    var that = this;
    if (that.before_close) that.before_close();
    $.colorbox.close();    
  },

  assets_to_include: function()
  {
    return [
      '//cdnjs.cloudflare.com/ajax/libs/tinymce/4.7.13/tinymce.min.js'
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
          width: 798,
          height: 300,
          fixed_placeholder: false,
          after_update: function() {            
   //         tinymce.EditorManager.execCommand('mceRemoveEditor', true, 'block_' + that.block_id + '_value');
            that.parent_controller.render_blocks();
        //    that.close(); 
          },
          after_cancel: function() { that.parent_controller.render_blocks(); that.close(); }
        }]
      });
    });
    that.autosize();        
  },

  print_crumbtrail: function()
  {    
    // var that = this;
    // var crumbs = $('<h2/>').css('margin-top', '0').css('padding-top', '0');
    // $.each(that.block.crumbtrail, function(i, h) {
    //   if (i > 0) crumbs.append(' > ');
    //   if ( i == 0 || (i == 1 && h['text'] == "Content" )) {
    //     crumbs.append($('<span/>').html(h['text']).data('block_id', h['block_id']));
    //   }
    //   else {
    //     crumbs.append($('<a/>').attr('href', '#').html(h['text']).data('block_id', h['block_id']).click(function(e) { 
    //       e.preventDefault();
    //       if (that.before_crumbtrail_click) that.before_crumbtrail_click();
    //       that.parent_controller.edit_block(parseInt($(this).data('block_id')));
    //     }));
    //   }
    // }); 
    $('#modal_crumbtrail').empty()     
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
        width: '798px',
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

$(document).trigger('richtext_modal_controller_loaded');
