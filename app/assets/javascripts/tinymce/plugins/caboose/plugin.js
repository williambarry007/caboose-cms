
tinymce.PluginManager.add('caboose', function(editor, url) {
  
  editor.addButton('caboose_save', {
    text: 'Save',
    icon: false,
    onclick: function() {
      tinymce.activeEditor.plugins.autosave.storeDraft();
              
      var control = ModelBinder.tinymce_current_control();  
      if (!control) return;
      control.save();
      control.cancel();
    }
  });
  
  editor.addButton('caboose_cancel', {
    text: 'Cancel',
    icon: false,
    onclick: function() {
      tinymce.activeEditor.plugins.autosave.storeDraft();
      
      var control = ModelBinder.tinymce_current_control();  
      if (!control) return;  
      control.cancel();                      
    }
  });
  
  // Adds a menu item to the tools menu
  //editor.addMenuItem('example', {
  //    text: 'Example plugin',
  //    context: 'tools',
  //    onclick: function() {
  //        // Open window with a specific url
  //        editor.windowManager.open({
  //            title: 'TinyMCE site',
  //            url: 'http://www.tinymce.com',
  //            width: 800,
  //            height: 600,
  //            buttons: [{
  //                text: 'Close',
  //                onclick: 'close'
  //            }]
  //        });
  //    }
  //});
});
