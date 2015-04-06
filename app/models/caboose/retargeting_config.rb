module Caboose
  class RetargetingConfig < ActiveRecord::Base
    self.table_name = "retargeting_configs"

    belongs_to :site
    attr_accessible :id,
      :site_id,
      :conversion_id,      
      :labels_function
    
    def labels(page)          
      return eval(self.custom_labels_function)    
    end
    
    def js_code(request, page)
      return "" if !self.site.use_retargeting
      
      str = ""      
      labels = self.labels(request, page)
      labels.each do |label|                    
        str << "<script type='text/javascript'>\n"
        str << "/* <![CDATA[ */\n"
        str << "var google_conversion_id = #{self.conversion_id};\n"
        str << "var google_conversion_label = '#{label}';\n"
        str << "var google_custom_params = window.google_tag_params;\n"
        str << "var google_remarketing_only = true;\n"
        str << "/* ]]> */\n"
        str << "</script>\n"
        str << "<script type='text/javascript' src='//www.googleadservices.com/pagead/conversion.js'></script>\n"
        str << "<noscript>\n"
        str << "<div style='display:inline;'>\n"
        str << "<img height='1' width='1' style='border-style:none;' alt='' src='//googleads.g.doubleclick.net/pagead/viewthroughconversion/#{self.conversion_id}/?value=1.00&amp;currency_code=USD&amp;label=#{label}&amp;guid=ON&amp;script=0'/>\n"
        str << "</div>\n"
        str << "</noscript>\n"
      end
      return str
    end
    
  end  
end
