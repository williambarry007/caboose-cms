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
  toolbar1: 'caboose_save caboose_cancel | bold italic forecolor backcolor | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image',
  image_advtab: true,
  external_plugins: { 'caboose': '#{Caboose::cdn_domain == '/' ? '' : "//#{Caboose::cdn_domain}"}/assets/tinymce/plugins/caboose/plugin.js' },
  setup: function(editor) {
    var control = ModelBinder.tinymce_control(editor.id);     
    editor.on('keyup', function(e) { control.tinymce_change(editor); });
  }
});
//]]>
</script>\n"
    end
    
    def parent_categories
      Caboose::Category.find(1).children.where(:status => 'Active')
    end
    
    def analytics_js
      return "" if @site.analytics_id.nil? || @site.analytics_id.strip.length == 0
      str = ''
      str << "<script>\n"
      str << "  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){\n"
      str << "  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),\n"
      str << "  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)\n"
      str << "  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');\n"
      str << "  ga('create', '#{@site.analytics_id}', 'auto');\n"
      str << "  ga('send', 'pageview');\n"
      str << "</script>\n"
      return str
    end
    
  end
end
