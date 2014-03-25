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

    def ab_testing_analytics_code
      return "var _gaq = _gaq || [];\n_gaq.push(['_setCustomVar', 1, 'caboose_ab_variants', #{Caboose.json(AbTesting.analytics_string)}]);"            
    end
    
    def pages_roles_with_prefix(top_roles, prefix)
      arr = []
      top_roles.each do |r|        
        arr = pages_roles_with_prefix_helper(arr, r, prefix, "")
      end
    end
    
    def pages_roles_with_prefix_helper(arr, role, prefix, str)      
      arr << "#{str}#{role.name}"
      role.children.each do |r|
        arr = pages_roles_with_prefix_helper(arr, r, prefix, "#{prefix}#{str}")
      end
      return arr
    end
          
  end
end
