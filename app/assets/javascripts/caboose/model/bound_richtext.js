
BoundRichText = BoundControl.extend({

  //el: false,
  //model: false,
  //attribute: false,
  //binder: false,
  
  width: false,
 
  init: function(params) {
    for (var thing in params)
      this[thing] = params[thing];
    
    this.el = this.el ? this.el : this.model.name.toLowerCase() + '_' + this.model.id + '_' + this.attribute.name;

    $('#'+this.el).wrap($('<div/>')
      .attr('id', this.el + '_container')
      .addClass('mb_container')
      .css('position', 'relative')
    );
    $('#'+this.el+'_container').empty();
    $('#'+this.el+'_container').append($('<div/>').attr('id', this.el + '_message'));
    $('#'+this.el+'_container').append($('<textarea/>').attr('id', this.el).attr('class', 'tinymce').attr('placeholder', 'empty').val(this.attribute.value));
    //$('#'+this.el+'_container').append($('<div/>').attr('id', this.el + '_placeholder').addClass('placeholder').append($('<span/>').html(this.attribute.nice_name + ': ')));
    if (this.attribute.width)  $('#'+this.el).css('width'  , this.attribute.width);
    if (this.attribute.height) $('#'+this.el).css('height' , this.attribute.height);
    var h = $('#'+this.el+'_placeholder').outerHeight();
    $('#'+this.el).attr('placeholder', 'empty').css('padding-top', '+=' + h).css('height', '-=' + h);
    
    var this2 = this;
    
    setTimeout(function() {      
      //tinymce.execCommand("mceAddEditor", false, this2.el);
      var ed = tinymce.EditorManager.createEditor(this2.el);            
      //var ed = new tinymce.Editor(this2.el, {
      //    setup: function (editor) {
      //      editor.on('init', function (e) { alert('Test'); });  
      //    }
      //  }, tinymce.Editormanager);
      //editor.on('init', function (e) { alert('Test'); });                    
      //ed.on('NodeChange', this2.tinymce_change);            
      //ed.on('click', function(e) { alert('tinymce was clicked'); });
      //ed.render();
    }, 100);    
  },
  
  tinymce_change: function(ed) {    
    if (ed.getContent() == this.attribute.value_clean)      
      ed.getBody().style.backgroundColor = "#fff";
    else
      ed.getBody().style.backgroundColor = "#fff799";
  },
  
  save: function() {
    var ed = tinymce.activeEditor;
    $('#'+this.el).val(ed.getContent());
                   
    this.attribute.value = $('#'+this.el).val();    
    if (this.attribute.value == this.attribute.value_clean)
      return;    
    
    var this2 = this;
    this.model.save(this.attribute, function(resp) {        
      if (resp.error)
      {        
        alert(resp.error);        
      }
      else
      {                
        $('#'+this2.el).val(this2.attribute.value);
        ed.setContent(this2.attribute.value);                        
        ed.getBody().style.backgroundColor = "#fff";
                      
        if (this2.binder.success)
          this2.binder.success(this2);
      }
    });
  },
  
  cancel: function() {    
    if (this.attribute.before_cancel)
      this.attribute.before_cancel();
    
    this.attribute.value = this.attribute.value_clean;
    $('#'+this.el).val(this.attribute.value);
            
    var ed = tinymce.activeEditor;
    ed.setContent(this.attribute.value);        
    ed.getBody().style.backgroundColor = "#fff";
  },
    
  error: function(str) {
    if (!$('#'+this.el+'_message').length)
    {
      $('#'+this.el+'_container').append($('<div/>')
        .attr('id', this.el + '_message')
        .css('width', $('#'+this.el).outerWidth())
      );
    }
    $('#'+this.el+'_message').hide();
    $('#'+this.el+'_message').html("<p class='note error'>" + str + "</p>");
    $('#'+this.el+'_message').slideDown();
    var this2 = this;
    setTimeout(function() { $('#'+this2.el+'_message').slideUp(function() { $(this).empty(); }); }, 3000);
  }
  
});

BoundRichText.test1 = function() {
  //alert('Testing');
};
