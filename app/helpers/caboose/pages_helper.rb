module Caboose
  module PagesHelper
    def pages_list(page)
      is_admin = @logged_in_user && @logged_in_user.is_allowed('all', 'all')
      str = "<ul>"
      str << pages_list_helper(page, is_admin)      
      str << "</ul>"
      return str
    end
    
    def pages_list_helper(page, is_admin)
      if is_admin || ((@logged_in_user && Page.permissible_actions(@logged_in_user, page.id).include?('edit')) ? true : false)
        str = "<li><a class='content' href='/admin/pages/#{page.id}/content'>#{page.title}</a><a class='icon3-settings' href='/admin/pages/#{page.id}'>Settings</a>"
      else
        str = "<li><span class='disabled'>#{page.title}</span>"
      end
      pchildren = page.children.select([:id, :title])
      if pchildren && pchildren.count > 0
        str << "<ul>"
        pchildren.each do |p|
          str << pages_list_helper(p, is_admin)
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
    
    def nav_link(p, css_class = nil, style = nil) 
      str = "<a "
      str << "class='#{css_class}' " if css_class
      str << "style='#{style}' " if style
      if p.redirect_url && p.redirect_url.strip.length > 0
        str << "href='#{p.redirect_url}' target='_blank'"
      else
        str << "href='/#{p.uri}'"
      end
      str << ">#{p.title}</a>"
      return str
    end

  end
end
