module Caboose
  module ApplicationHelper
    def caboose_tinymce
      return "
<script src='//tinymce.cachefly.net/4.0/tinymce.min.js'></script>
<script type='text/javascript'>
//<![CDATA[
tinyMCE.init({
  selector: 'textarea.tinymce',
  width: '800px',
  height: '300px',
  convert_urls: false,
  plugins: 'advlist autolink lists link image charmap print preview hr anchor pagebreak searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking table contextmenu directionality emoticons template paste textcolor caboose',
  toolbar1: 'caboose_save caboose_cancel | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image',
  image_advtab: true,
  external_plugins: { 'caboose': '//#{Caboose::CDN_DOMAIN}/assets/tinymce/plugins/caboose/plugin.js' },
  setup: function(editor) {
    var control = ModelBinder.tinymce_control(editor.id);     
    editor.on('keyup', function(e) { control.tinymce_change(editor); });
  }
});
//]]>
</script>\n"
    end
  end
end
