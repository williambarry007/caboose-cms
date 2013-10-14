module Caboose
  class PageBarGenerator  
    #
    # Parameters:
    #	params:	array of key/value pairs that must include the following:
    #		base_url: 		url without querystring onto which the parameters are added.	
    #		itemCount:		Total number of items.
    #
    #	In addition, the following parameters are not required but may be 
    #	included in the array:	
    #		itemsPerPage:	Number of items you want to show per page. Defaults to 10 if not present.
    #		page: Current page number.  Defaults to 0 if not present.
    #
    attr_accessor :params, :options
  	
  	def initialize(post_get, params = nil, options = nil)
  	  
  	  params  = {} if params.nil?
  	  options = {} if options.nil?
  	  
  		# Note: a few keys are required:
  		# base_url, page, itemCount, itemsPerPage
  		@params = {}
  		@options = {
  		  'model'           => '',
  			'sort' 			      => '',
  			'desc' 			      => 0,
  			'base_url'		    => '',
  			'page'			      => 1,
  			'item_count'		  => 0,
  			'items_per_page'  => 10
  		}      
  		params.each   { |key, val| @params[key]  = val }
  		options.each  { |key, val| @options[key] = val }
  		@params.each  { |key, val| @params[key]  = post_get[key].nil? ? val : post_get[key] }			
  		@options.each { |key, val| @options[key] = post_get[key].nil? ? val : post_get[key] }
  		fix_desc
  		@options['item_count'] = @options['model'].constantize.where(where).count  		  		
  	end
  	
  	def fix_desc
  	  @options['desc'] = 0 and return if @options['desc'].nil?
  	  return if @options['desc'] == 1
  	  return if @options['desc'] == 0
  	  @options['desc'] = 1 and return if @options['desc'] == 'true' || @options['desc'].is_a?(TrueClass)
  	  @options['desc'] = 0 and return if @options['desc'] == 'false' || @options['desc'].is_a?(FalseClass)  	  
  	  @options['desc'] = @options['desc'].to_i 
  	end
  	
  	def ok(val)
      return false if val.nil?
      return true  if val.is_a? Array
      return true  if val.is_a? Hash
      return true  if val.is_a? Integer
      return true  if val.is_a? Fixnum
      return true  if val.is_a? Float
      return true  if val.is_a? Bignum
      return true  if val.is_a? TrueClass
      return true  if val.is_a? FalseClass
      return false if val == ""
      return true
  	end
  	
  	def items  	    	  
    	#return @options['model'].constantize.where(where).limit(limit).offset(offset).reorder(reorder).all
    	return @options['model'].constantize.where(where).limit(limit).offset(offset).reorder(reorder).all
  	end
  		
  	def generate
  	    	  
  		# Check for necessary parameter values
  		return false if !ok(@options['base_url']) # Error: base_url is required for the page bar generator to work.
  		return false if !ok(@options['item_count']) # Error: itemCount is required for the page bar generator to work.
  		
  		# Set default parameter values if not present
  		@options['items_per_page'] = 10  if @options["items_per_page"].nil?
  		@options['page']           = 1   if @options["page"].nil?		
  		
  		# Variables to make the search form work 
  		vars = get_vars()
  		page = @options["page"].to_i
  				
  		# Max links to show (must be odd) 
  		total_links = 5
  		prev_page = page - 1
  		next_page = page + 1
  		total_pages = (@options['item_count'].to_f / @options['items_per_page'].to_f).ceil
  		
  		if (total_pages < total_links)
  			start = 1
  			stop = total_pages			
  		else
  			start = page - (total_links/2).floor			
  			start = 1 if start < 1
  			stop = start + total_links - 1
  			
  			if (stop > total_pages)
  				stop = total_pages				
  				start = stop - total_links  				
  				start = 1 if start < 1
  			end
  		end
  		
  		base_url = @params['base_url']
  		str = ''
  		str << "<p>Results: showing page #{page} of #{total_pages}</p>\n"
  		
  		if (total_pages > 1)
  		  str << "<div class='page_links'>\n"
  		  if (page > 1)
  		    str << "<a href='#{base_url}?#{vars}&page=#{prev_page}'>Previous</a>"
  	    end
  		  for i in start..stop
  		  	if (page != i)
  		  	  str << "<a href='#{base_url}?#{vars}&page=#{i}'>#{i}</a>"
  		  	else
  		  		str << "<span class='current_page'>#{i}</span>"
  		  	end
  		  end
  		  if (page < total_pages)
  		  	str << "<a href='#{base_url}?#{vars}&page=#{next_page}'>Next</a>"
  		  end
  		  str << "</div>\n"
      end
      
  		return str
  	end
  	
  	def get_vars()  
  	  vars = []
  	  @params.each do |k,v|
  	    vars.push("#{k}=#{v}") if !v.nil? && v.length > 0 
  	  end
  	  return URI.escape(vars.join('&'))
  	end
  	
    def sortable_table_headings(cols)
      vars = get_vars()
    	str = ''
      
    	# key = sort field, value = text to display
    	cols.each do |sort, text|    		
    		arrow = @options['sort'] == sort ? (@options['desc'] == 1 ? ' &uarr;' : ' &darr;') : ''    		
    		link = @options['base_url'] + "?#{vars}&sort=#{sort}&desc=" + (@options['desc'] == 1 ? "0" : "1")
    		str += "<th><a href='#{link}'>#{text}#{arrow}</a></th>\n"
    	end
    	return str  	
    end
    
    def where
      sql = []
      values = []      
  	  @params.each do |k,v|
        next if v.nil? || v.length == 0
        
        sql2 = ""
        if k.ends_with?('_gte')
          sql2 = "#{k[0..-5]} >= ?"
        elsif k.ends_with?('_gt')
          sql2 = "#{k[0..-4]} > ?"
        elsif k.ends_with?('_lte')
          sql2 = "#{k[0..-5]} <= ?"
        elsif k.ends_with?('_lt')
          sql2 = "#{k[0..-4]} < ?"
        elsif k.ends_with?('_bw')
          sql2 = "upper(#{k[0..-4]}) like ?"
          v = v.kind_of?(Array) ? v.collect{ |v2| "#{v2}%".upcase } : "#{v}%".upcase          
        elsif k.ends_with?('_ew')
          sql2 = "upper(#{k[0..-4]}) like ?"
          v = v.kind_of?(Array) ? v.collect{ |v2| "%#{v2}".upcase } : "%#{v}".upcase
        elsif k.ends_with?('_like')
          sql2 = "upper(#{k[0..-6]}) like ?"
          v = v.kind_of?(Array) ? v.collect{ |v2| "%#{v2}%".upcase } : "%#{v}%".upcase
        else          
          sql2 = "#{k} = ?"
        end
        
        if v.kind_of?(Array)
          sql2 = "(" + v.collect{ |v2| "#{sql2}" }.join(" or ") + ")"
          v.each { |v2| values << v2 }
        else              
          values << v
        end
        sql << sql2                          
  	  end
  	  sql_str = sql.join(' and ')
  	  sql = [sql_str]  	   	  
  	  values.each { |v| sql << v }        	  
  	  return sql        	  
    end
    
    def limit
      return @options['items_per_page'].to_i
    end
    
    def offset
      return (@options['page'].to_i - 1) * @options['items_per_page'].to_i
    end
    
    def reorder
      str = "id"
      if (!@options['sort'].nil? && @options['sort'].length > 0)
        str = "#{@options['sort']}"
      end
      str << " desc" if @options['desc'] == 1       
      return str
    end
  end
end
