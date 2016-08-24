
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
