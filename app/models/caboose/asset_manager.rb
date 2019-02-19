module Caboose
  class AssetManager
    def AssetManager.referenced_assets_in_views
      
      files = []

      # Stylesheets
      str = `grep -Rh stylesheet_link_tag #{Rails.root}/app/views`
      str << `grep -Rh stylesheet_link_tag #{Rails.root}/sites/*/views`
      str.strip.split("\n").each do |line|
        file = self.replace_css_line(line)
        files << (file.ends_with?('.css') ? "#{file}" : "#{file}.css") if file
      end

      # Javascript
      str = `grep -Rh javascript_include_tag #{Rails.root}/app/views`      
      str << `grep -Rh javascript_include_tag #{Rails.root}/sites/*/views`
      str.strip.split("\n").each do |line|
        file = self.replace_js_line(line)
        files << (file.ends_with?('.js') ? "#{file}" : "#{file}.js") if file
      end
      
      return files.uniq
      
    end
    
    def AssetManager.referenced_assets_in_caboose_views
      
      # Get anything that was referenced in the views
      spec = Gem::Specification.find_by_name('caboose-cms')            
      files = []
      
      # Stylesheets
      str = `grep -Rh stylesheet_link_tag #{spec.gem_dir}/app/views`      
      str.strip.split("\n").each do |line|
        file = self.replace_css_line(line)
        files << (file.ends_with?('.css') ? "#{file}" : "#{file}.css") if file                
      end

      # Javascript
      str = `grep -Rh javascript_include_tag #{spec.gem_dir}/app/views`      
      str.strip.split("\n").each do |line|
        file = self.replace_js_line(line)        
        files << (file.ends_with?('.js') ? "#{file}" : "#{file}.js") if file
      end
      
      #puts "--------------------------------------------------------------------"
      #puts files.uniq
      #puts "--------------------------------------------------------------------"      
      #return files.uniq
            
    end        
    
    def AssetManager.replace_css_line(str)
      return nil if str.include?('#{') || str.include?('@') || str.include?(".each do")      
      str = str
        .gsub('<%=','')
        .gsub('%>','')
        .gsub('gzip_stylesheet_link_tag','')
        .gsub('stylesheet_link_tag','')
        .gsub('(','')
        .gsub(')','')
        .gsub('"','')
        .gsub("'",'')
        .gsub(',','')
        .gsub(':media => "all"','')
        .strip.split(' ').first.strip
      return nil if str.length == 0 || str.starts_with?('#') || str.starts_with?('http') || str.starts_with?('//')
      return str
    end
    
    def AssetManager.replace_js_line(str)
      return nil if str.include?('#{') || str.include?('@') || str.include?(".each do")
      str = str
        .gsub('<%=','')
        .gsub('<%','')
        .gsub('%>','')
        .gsub('gzip_javascript_include_tag','')
        .gsub('javascript_include_tag','')
        .gsub('(','')
        .gsub(')','')
        .gsub('"','')
        .gsub("'",'')
        .gsub(",",'')
        .strip.split(' ').first.strip              
      return nil if str.length == 0 || str.starts_with?('#') || str.starts_with?('http') || str.starts_with?('//')
      return str      
    end
      
  end
end
      