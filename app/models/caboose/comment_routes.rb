module Caboose
  class CommentRoutes
  
    def CommentRoutes.parse_controllers    
    
      classes = []        
      files = Dir.glob(Rails.root.join('app', 'controllers','*.rb'))
      for file in files    
        f = Rails.root.join('app', 'controllers', file)
        f2 = File.open(f, "r")
        
        class_name = nil
        class_priority = 20
        route_priority = 20
        uris = []
        actions = []
        f2.each_line do |line|      
          line = line.strip        
          if line =~ /^(.*?)class (.*?)Controller(.*?)$/
            class_name = line.gsub(/^(.*?)class (.*?)Controller(.*?)$/, '\2').gsub(/([A-Z])/, '_\1').downcase
            class_name[0] = '' if class_name[0] == '_'
          elsif line =~ /# @class_route_priority \d/
            class_priority = line.gsub(/# @class_route_priority (\d*?)$/, '\1').to_i
          elsif line =~ /# @route_priority \d/
            route_priority = line.gsub(/# @route_priority (\d*?)$/, '\1').to_i
          elsif line.starts_with?('def ')
            actions << [line.gsub('def ', ''), uris, route_priority]              
            uris = []
            route_priority = 20
          elsif line =~ /# @route GET (.*?)/       then uris << "get    \"#{line.gsub(/# @route GET (.*?)/       , '\1')}\""          
          elsif line =~ /# @route POST (.*?)/      then uris << "post   \"#{line.gsub(/# @route POST (.*?)/      , '\1')}\""          
          elsif line =~ /# @route PUT (.*?)/       then uris << "put    \"#{line.gsub(/# @route PUT (.*?)/       , '\1')}\""          
          elsif line =~ /# @route DELETE (.*?)/    then uris << "delete \"#{line.gsub(/# @route DELETE (.*?)/    , '\1')}\""
          end
        end      
        classes << [class_name, actions, class_priority]
      end

      routes = []
      classes.sort_by{ |arr| arr[2] }.each do |carr|
        
        class_name = carr[0]
        actions = carr[1]
        
        # Get the longest URI so we can make routes that line up vertically
        longest = ''
        actions.each{ |action, uris| uris.each{ |uri| longest = uri if uri.length > longest.length }}
        length = longest.length + 1
        
        # Make the route line
        actions.sort_by{ |arr| arr[2] }.each do |arr|
          action = arr[0]
          uris = arr[1]
          uris.each do |uri|
            #puts "#{uri.ljust(length, ' ')} => \"#{class_name}\##{action}\""
            routes << "#{uri.ljust(length, ' ')} => \"#{class_name}\##{action}\"" 
          end
        end
        puts ""
      end      
      return routes      
    end
    
  end
end