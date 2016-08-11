module Caboose
  class CommentRoutes
  
    def CommentRoutes.parse_controllers
      return CommentRoutes.controller_routes
    end
      
    def CommentRoutes.controller_routes(controller = nil)
      
      controller = controller[1] if controller && controller.is_a?(Array)            
      controller_paths = []
      Gem.loaded_specs.each do |name, s|
        controller_paths << s.full_gem_path        
      end
      Rails.application.config.paths['app/controllers'].each do |controller_path|                
        controller_paths << Rails.root.join(controller_path)
      end
          
      classes = {'zzz_all_domains' => []}       
      controller_paths.each do |controller_path|                
        #files = Dir.glob(Rails.root.join(controller_path, '*.rb'))        
        #files = controller ? Dir.glob(Rails.root.join(controller_path, "#{controller}_controller.rb")) : Dir.glob(Rails.root.join(controller_path, '**/*.rb'))
        #files = controller ? Dir.glob(Rails.root.join(controller_path, "#{controller}_controller.rb")) : Dir.glob(Rails.root.join(controller_path, '*.rb'))        
        #files = controller ? Dir.glob("#{controller_path}/#{controller}_controller.rb") : Dir.glob("#{controller_path}/*.rb")                          
        files = controller ? Dir.glob("#{controller_path}/**/#{controller.gsub(/(.*?)::(.*?)/, '\2')}_controller.rb") : Dir.glob("#{controller_path}/**/*_controller.rb")
        #files = Dir.glob("#{controller_path}/**/*_controller.rb")        
        for file in files
          f2 = File.open(file, "r")
                  
          domains = []
          domains_constrainer = false
          module_name = nil
          class_name = nil
          class_priority = 20
          route_priority = 20
          custom_route_priority = false          
          uris = []
          actions = []
          f2.each_line do |line|      
            line = line.strip        
            if line =~ /^module (.*?)$/
              module_name = line.gsub(/^module (.*?)$/, '\1').gsub(/([A-Z])/, '_\1').downcase
              module_name[0] = '' if module_name[0] == '_'
            elsif line =~ /^(.*?)class (.*?)Controller(.*?)$/
              class_name = line.gsub(/^(.*?)class (.*?)Controller(.*?)$/, '\2').gsub(/([A-Z])/, '_\1').downcase
              class_name[0] = '' if class_name[0] == '_'
              class_name = "#{module_name}::#{class_name}" if module_name
            elsif line =~ /# @route_domain (.*?)$/
              # Ignore if we have a domain constrainer
              if domains.is_a?(Array)
                domain = line.gsub(/# @route_domain (.*?)$/, '\1')
                domains << domain if !domains.include?(domain)
              end
            elsif line =~ /# @route_domain_constrainer (.*?)$/
              domains = line.gsub(/# @route_domain_constrainer (.*?)$/, '\1')              
            elsif line =~ /# @route_constraints (.*?)$/            
              constraints = line.gsub(/# @route_constraints (.*?)$/, '\1')
              uris.last[1] = constraints if uris.length > 0
              constraints = nil
            elsif line =~ /# @class_route_priority \d/
              class_priority = line.gsub(/# @class_route_priority (\d*?)$/, '\1').to_i
            elsif line =~ /# @route_priority \d/
              custom_route_priority = line.gsub(/# @route_priority (\d*?)$/, '\1').to_i              
            elsif line.starts_with?('def ')                                           
              actions << [line.gsub('def ', ''), uris, custom_route_priority ? custom_route_priority : route_priority]                            
              uris = []
              route_priority = route_priority + 1 if !custom_route_priority
              custom_route_priority = false
              constraints = nil
            elsif line =~ /# @route GET (.*?)/       then uris << ["get    \"#{line.gsub(/# @route GET (.*?)/       , '\1').strip}\"", nil]              
            elsif line =~ /# @route POST (.*?)/      then uris << ["post   \"#{line.gsub(/# @route POST (.*?)/      , '\1').strip}\"", nil]              
            elsif line =~ /# @route PUT (.*?)/       then uris << ["put    \"#{line.gsub(/# @route PUT (.*?)/       , '\1').strip}\"", nil]              
            elsif line =~ /# @route DELETE (.*?)/    then uris << ["delete \"#{line.gsub(/# @route DELETE (.*?)/    , '\1').strip}\"", nil]              
            end
          end
          ds = domains.is_a?(Array) ? (domains.count > 0 ? domains.sort.join(' ') : 'zzz_all_domains') : "CONSTRAIN #{domains}" 
          classes[ds] = [] if classes[ds].nil?
          classes[ds] << [class_name, actions, class_priority]
        end
      end
           
      routes = []
      classes.sort_by{ |domain, domain_classes| domain }.to_h.each do |domain, domain_classes|
                        
        if domain != 'zzz_all_domains'                      
          if domain.starts_with?('CONSTRAIN ')
            constrainer = domain.gsub('CONSTRAIN ', '')
            routes << "constraints #{constrainer}.new do"
          else
            domains = domain.split(' ').collect{ |d| "'#{d}'" }.join(', ')
            routes << "constraints Caboose::DomainConstraint.new([#{domains}]) do"                      
          end            
        end
        domain_classes.sort_by{ |arr| arr[2] }.each do |carr|
        
          class_name = carr[0]
          actions = carr[1]
          
          # Get the longest URI so we can make routes that line up vertically
          longest = ''
          actions.each{ |action, uris| uris.each{ |uri_arr| longest = uri_arr[0] if uri_arr[0].length > longest.length }}
          length = longest.length + 1
          
          # Make the route line         
          actions.sort_by{ |arr| arr[2] }.each do |arr|
            action = arr[0]
            uris = arr[1]
            uris.each do |uri_arr|
              uri = uri_arr[0]
              constraints = uri_arr[1]
              # puts "#{uri.ljust(length, ' ')} => \"#{class_name}\##{action}\""
              route = "#{uri.ljust(length, ' ')} => \"#{class_name}\##{action}\""
              route = "#{route}, :constraints => #{constraints}" if constraints
              routes << route              
            end
          end
          #puts ""
          routes << ""          
        end
        routes << "end" if domain != 'zzz_all_domains'
      end      
      #puts routes
      return routes.join("\n")      
    end
  
    def CommentRoutes.split_route(line)
      return nil if line.nil?
      line = line.strip
      
      #return ['get'    , line.gsub(/^get (.*?)=>(.*?)$/    , '\1').strip.gsub('"', '').gsub("'", ''), line.gsub(/^get (.*?)=>(.*?)$/    , '\2').strip.gsub('"', '').gsub("'", '')] if line =~ /^get (.*?)=>(.*?)$/
      #return ['post'   , line.gsub(/^post (.*?)=>(.*?)$/   , '\1').strip.gsub('"', '').gsub("'", ''), line.gsub(/^post (.*?)=>(.*?)$/   , '\2').strip.gsub('"', '').gsub("'", '')] if line =~ /^post (.*?)=>(.*?)$/
      #return ['put'    , line.gsub(/^put (.*?)=>(.*?)$/    , '\1').strip.gsub('"', '').gsub("'", ''), line.gsub(/^put (.*?)=>(.*?)$/    , '\2').strip.gsub('"', '').gsub("'", '')] if line =~ /^put (.*?)=>(.*?)$/
      #return ['delete' , line.gsub(/^delete (.*?)=>(.*?)$/ , '\1').strip.gsub('"', '').gsub("'", ''), line.gsub(/^delete (.*?)=>(.*?)$/ , '\2').strip.gsub('"', '').gsub("'", '')] if line =~ /^delete (.*?)=>(.*?)$/
      
      if line =~ /^get (.*?)=>(.*?)$/ || line =~ /^post (.*?)=>(.*?)$/ || line =~ /^put (.*?)=>(.*?)$/ || line =~ /^delete (.*?)=>(.*?)$/
        arr = [
          line.gsub(/^(\w*?) (.*?)=>(.*?)$/    , '\1').strip.gsub('"', '').gsub("'", ''), 
          line.gsub(/^(\w*?) (.*?)=>(.*?)$/    , '\2').strip.gsub('"', '').gsub("'", ''), 
          line.gsub(/^(\w*?) (.*?)=>(.*?)$/    , '\3').strip.gsub('"', '').gsub("'", '')
        ]
        arr[1] = "/#{arr[1]}" if !arr[1].starts_with?('/')
        return arr
      end               
      return nil
    end
    
    def CommentRoutes.in_routes_array(route, routes_array)
      return false if route.nil? || route.count < 3
      routes_array.each do |route2|
        next if route2.nil? || route2.count < 3        
        return true if route[0] == route2[0] && route[1] == route2[1] && route[2] == route2[2]
      end
      return false
    end
    
    def CommentRoutes.compare_routes(controller, route_file)
      
      controller = controller[1] if controller && controller.is_a?(Array)        
      routes_in_routes_file = []
      file = File.open(route_file ? route_file : Rails.root.join('config', 'routes.rb'), "r")      
      file.each_line do |line|        
        line = line.strip
        arr = self.split_route(line)
        routes_in_routes_file << arr if arr && arr[2].starts_with?("#{controller}#")                  
      end
            
      routes_in_controllers = []
      self.controller_routes(controller).split("\n").each do |route|
        route = route.strip
        next if route.length == 0
        routes_in_controllers << self.split_route(route)
      end
      
      all_routes = []
      
      # See what routes are in the controller routes but not in routes file
      routes_not_in_routes_file = []
      routes_in_controllers.each do |route|
        next if route.nil? || route.count != 3        
        all_routes << [route[0], route[1], route[2], 'Yes', self.in_routes_array(route, routes_in_routes_file) ? 'Yes' : 'No']
      end
      
      # See what routes are in the routes file but not in the controllers
      routes_not_in_controllers = []
      routes_in_routes_file.each do |route|
        next if route.nil? || route.count != 3
        if !self.in_routes_array(route, all_routes)
          all_routes << [route[0], route[1], route[2], 'No', 'Yes']
        end        
      end
      
      lengths = [0, 0, 0]      
      all_routes.each do |route|
        lengths[0] = route[0].length if route[0].length > lengths[0]
        lengths[1] = route[1].length if route[1].length > lengths[1]
        lengths[2] = route[2].length if route[2].length > lengths[2]        
      end                    
                                  
      puts "#{"Verb".ljust(lengths[0], ' ')} #{"URI".ljust(lengths[1], ' ')} #{"Action".ljust(lengths[2], ' ')} #{"In Controller".ljust(14, ' ')} #{"In Routes File".ljust(14, ' ')}"
      puts "#{"".ljust(lengths[0], '-')} #{"".ljust(lengths[1], '-')} #{"".ljust(lengths[2], '-')} #{"".ljust(14, '-')} #{"".ljust(14, '-')}"
      all_routes.each do |route|          
        #next if route[3] == 'Y' && route[4] == 'Y'        
        puts "#{route[0].ljust(lengths[0], ' ')} #{route[1].ljust(lengths[1], ' ')} #{route[2].ljust(lengths[2], ' ')} #{route[3].ljust(14, ' ')} #{route[4].ljust(14, ' ')}"
      end              
      puts "\n"
                                                  
    end
    
  end
end