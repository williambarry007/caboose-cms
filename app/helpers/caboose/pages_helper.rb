module Caboose
  module PagesHelper
    def pages_list(page)
      str = "<ul>"
      str << pages_list_helper(page)      
      str << "</ul>"
      return str
    end
    
    def pages_list_helper(page)
      str = "<li><a href='/admin/pages/#{page.id}/edit'>#{page.title}</a>"
      if page.children && page.children.count > 0
        str << "<ul>"
        page.children.each do |p|
          str << pages_list_helper(p)
        end
        str << "</ul>"
      end
      str << "</li>"
      return str
    end
    
    def ab_variants_analytics_code
      str = session['ab_variants_analytics_string']
      return "var _gaq = _gaq || [];\n_gaq.push(['_setCustomVar', 1, 'caboose_ab_variants', #{Caboose.json(str)}]);"            
    end
    
  end
end
