# Note: 
#   For includes to work with namespaces other than the root namespace, the 
#   full namespaced class_name has to be set in the model on the association 
#   being included.  For example:
#
#   class Animals::Dog
#     has_many :friends, :class_name => 'Animals::Dog'
#   end
#   

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
    attr_accessor :params, :options, :custom_url_vars    
  	
    #def initialize(post_get, params = nil, options = nil, &custom_url_vars = nil)
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
  			'items_per_page'  => 10,  			
  			'abbreviations'   => {},
  			'skip'            => [], # params to skip when printing the page bar  			
  			'includes'        => nil # Hash of association includes
  			                         # {
  			                         #   search_field_1 => [association_name, join_table, column_name],
  			                         #   search_field_2 => [association_name, join_table, column_name]
  			                         # }  			
  		}      
  		params.each   { |key, val| @params[key]  = val }
  		options.each  { |key, val| @options[key] = val }
  		
  		#@params.each  { |key, val|  		  
  		#  k = @options['abbreviations'].include?(key) ? @options['abbreviations'][key] : nil  		  
  		#  @params[key] = post_get[key].nil? ? (k && !post_get[k].nil? ? post_get[k] : val) : post_get[key]  		          
  		#}
  		
  		new_params = {}
  		keys_to_delete = []
  		@params.each  { |key, val|
  		  next if !@options['abbreviations'].has_key?(key)  		  
  		  long_key = @options['abbreviations'][key]  		  
        new_params[long_key] = val
        keys_to_delete << key        
  		}
  		keys_to_delete.each { |k| @params.delete(k) }
  		new_params.each { |k,v| @params[k] = v }        		
  		@params.each  { |k,v| @params[k]  = post_get[k] ? post_get[k] : v }        			
  		@options.each { |k,v| @options[k] = post_get[k] ? post_get[k] : v }
  		
  		#@custom_url_vars = custom_url_vars if !custom_url_vars.nil?
  		@use_url_params = @options['use_url_params'].nil? ? Caboose.use_url_params : @options['use_url_params']
      
  		fix_desc
  		set_item_count
  	end
  	
  	def set_item_count
  	  @options['item_count'] = model_with_includes.where(where).count
  	end
  	
  	def model_with_includes
  	  m = @options['model'].constantize
  		return m if @options['includes'].nil?
  		
  		# See if any fields that we know have includes have values
  		associations = []
  		@options['includes'].each do |field, arr|    		          
  		  next if @params[field].nil? || (@params[field].kind_of?(String) && @params[field].length == 0)  		  
        associations << arr[0]
      end
      # See if any fields in the sort option are listed in a table_name.column_name format
      if @options['sort']
        @options['sort'].split(',').each do |col|
          tbl_col = col.split('.')
          associations << association_for_table_name(tbl_col[0]) if tbl_col && tbl_col.count > 1          
        end
      end
      # See if any parameters are listed in a table_name.column_name format
      @params.each do |k,v|
        k.split('_concat_').each do |col,v2|        
          tbl_col = col.split('.')
          associations << association_for_table_name(tbl_col[0]) if tbl_col && tbl_col.count > 1
        end
      end
  		associations.uniq.each { |assoc| m = m.includes(assoc) }
  		return m
  	end
  	
  	def association_for_table_name(table_name)
  	  @options['includes'].each do |field, arr|
  	    return arr[0] if table_name_of_association(arr[0]) == table_name                              
      end
      return false
    end
  	
  	def table_name_of_association(assoc)
      ap assoc
  	  return @options['model'].constantize.reflect_on_association(assoc.to_sym).class_name.constantize.table_name
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
      Caboose.log(where)  		
  		assoc = model_with_includes.where(where)
    	if @options['items_per_page'] != -1
    	  assoc = assoc.limit(limit).offset(offset)
    	end
    	return assoc.reorder(reorder).all
  	end
  	
  	def all_items
  	  return model_with_includes.where(where).all
    end
  	
  	def item_values(attribute)
  	  arr = []
  	  model_with_includes.where(where).all.each do |m|
  	    arr << m[attribute]
  	  end    	
    	return arr.uniq
    end  	  
  		
  	def generate
  	    	  
  		# Check for necessary parameter values
  		return false if !ok(@options['base_url']) # Error: base_url is required for the page bar generator to work.
  		return false if !ok(@options['item_count']) # Error: itemCount is required for the page bar generator to work.
  		
  		# Set default parameter values if not present
  		@options['items_per_page'] = 10  if @options["items_per_page"].nil?
  		@options['page']           = 1   if @options["page"].nil?		
  		
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
  		
  		base_url = url_with_vars      
      base_url << (@use_url_params ? "/" : (base_url.include?("?") ? "&" : "?"))      
      keyval_delim = @use_url_params ? "/" : "="
  		var_delim    = @use_url_params ? "/" : "&"            
  		
  		str = ''
  		str << "<p>Results: showing page #{page} of #{total_pages}</p>\n"
  		
  		if (total_pages > 1)
  		  str << "<div class='page_links'>\n"
  		  if (page > 1)
  		    str << "<a href='#{base_url}page#{keyval_delim}#{prev_page}'>Previous</a>"
  	    end
  		  for i in start..stop
  		  	if (page != i)
  		  	  str << "<a href='#{base_url}page#{keyval_delim}#{i}'>#{i}</a>"
  		  	else
  		  		str << "<span class='current_page'>#{i}</span>"
  		  	end
  		  end
  		  if (page < total_pages)
  		  	str << "<a href='#{base_url}page#{keyval_delim}#{next_page}'>Next</a>"
  		  end
  		  str << "</div>\n"
      end
      
  		return str
  	end
  	
  	def url_with_vars()
  	  if !@custom_url_vars.nil?
  	    return @custom_url_vars.call @options['base_url'], @params
  	  end
  	  
  	  vars = []
  	  @params.each do |k,v|  	    
  	    next if @options['skip'].include?(k)
  	    k = @options['abbreviations'].include?(k) ? @options['abbreviations'][k] : k  	      	    
  	    if v.kind_of?(Array)
  	      v.each do |v2|  	        
  	        if @use_url_params
  	          vars.push("#{k}/#{v2}") if !v2.nil?
  	        else
  	          vars.push("#{k}[]=#{v2}") if !v2.nil?
  	        end
  	      end
  	    else  	      
  	      next if v.nil? || (v.kind_of?(String) && v.length == 0)
  	      if @use_url_params
  	        vars.push("#{k}/#{v}")
  	      else
  	        vars.push("#{k}=#{v}")
  	      end  	        
  	    end  	      	    
  	  end
  	  vars.push("sort=#{@options['sort']}")
  		vars.push("desc=#{@options['desc']}")  		
  		vars.push("page=#{@options['page']}")  			
  	  return "#{@options['base_url']}" if vars.length == 0
  	  if @use_url_params
  	    vars = URI.escape(vars.join('/'))  	    
  	    return "#{@options['base_url']}/#{vars}"
  	  end
  	  vars = URI.escape(vars.join('&'))
  	  return "#{@options['base_url']}?#{vars}"
  	end
  	
    def sortable_table_headings(cols)
      base_url = url_with_vars
      base_url << (base_url.include?("?") ? "&" : "?")
    	str = ''
      
    	# key = sort field, value = text to display
    	cols.each do |sort, text|    		
    		arrow = @options['sort'] == sort ? (@options['desc'] == 1 ? ' &uarr;' : ' &darr;') : ''
    		#link = @options['base_url'] + "?#{vars}&sort=#{sort}&desc=" + (@options['desc'] == 1 ? "0" : "1")
        link = "#{base_url}sort=#{sort}&desc=" + (@options['desc'] == 1 ? "0" : "1")            		
    		str += "<th><a href='#{link}'>#{text}#{arrow}</a></th>\n"
    	end
    	return str  	
    end
    
    def where
      sql = []
      values = []
      table = @options['model'].constantize.table_name      
  	  @params.each do |k,v|
        next if v.nil? || (v.kind_of?(String) && v.length == 0)
        
        col = nil        
        if @options['includes'] && @options['includes'].include?(k)           
          arr = @options['includes'][k]
          col = "#{table_name_of_association(arr[0])}.#{arr[1]}"
        end        
        if k.include?('_concat_')
          #arr = k.split('_concat_')
          #col1 = arr[0]
          #col2 = arr[1]           
          #
          #col2 = col2[0..-5] if col2.ends_with?('_gte')
          #col2 = col2[0..-4] if col2.ends_with?('_gt')                        
          #col2 = col2[0..-5] if col2.ends_with?('_lte')                        
          #col2 = col2[0..-4] if col2.ends_with?('_lt')                                  
          #col2 = col2[0..-4] if col2.ends_with?('_bw')                                              
          #col2 = col2[0..-4] if col2.ends_with?('_ew')
          #col2 = col2[0..-6] if col2.ends_with?('_like')
          #                                  
          #col = "concat(#{col1},' ', #{col2})"
          
          arr = k.split('_concat_')                                         
          arr[arr.count-1] = arr[arr.count-1][0..-5] if k.ends_with?('_gte')
          arr[arr.count-1] = arr[arr.count-1][0..-4] if k.ends_with?('_gt')                        
          arr[arr.count-1] = arr[arr.count-1][0..-5] if k.ends_with?('_lte')                        
          arr[arr.count-1] = arr[arr.count-1][0..-4] if k.ends_with?('_lt')                                  
          arr[arr.count-1] = arr[arr.count-1][0..-4] if k.ends_with?('_bw')                                              
          arr[arr.count-1] = arr[arr.count-1][0..-4] if k.ends_with?('_ew')
          arr[arr.count-1] = arr[arr.count-1][0..-6] if k.ends_with?('_like')                                            
          col = "concat(#{arr.join(",' ',")})"
        end
        
        sql2 = ""
        if k.ends_with?('_gte')
          col = "#{table}.#{k[0..-5]}" if col.nil?
          sql2 = "#{col} >= ?"
        elsif k.ends_with?('_gt')
          col = "#{table}.#{k[0..-4]}" if col.nil?
          sql2 = "#{col} > ?"
        elsif k.ends_with?('_lte')
          col = "#{table}.#{k[0..-5]}" if col.nil?
          sql2 = "#{col} <= ?"
        elsif k.ends_with?('_lt')
          col = "#{table}.#{k[0..-4]}" if col.nil?          
          sql2 = "#{col} < ?"
        elsif k.ends_with?('_bw')
          col = "#{table}.#{k[0..-4]}" if col.nil?
          sql2 = "upper(#{col}) like ?"
          v = v.kind_of?(Array) ? v.collect{ |v2| "#{v2}%".upcase } : "#{v}%".upcase          
        elsif k.ends_with?('_ew')
          col = "#{table}.#{k[0..-4]}" if col.nil?
          sql2 = "upper(#{col}) like ?"
          v = v.kind_of?(Array) ? v.collect{ |v2| "%#{v2}".upcase } : "%#{v}".upcase
        elsif k.ends_with?('_like')
          col = "#{table}.#{k[0..-6]}" if col.nil?
          sql2 = "upper(#{col}) like ?"
          v = v.kind_of?(Array) ? v.collect{ |v2| "%#{v2}%".upcase } : "%#{v}%".upcase
        else
          col = "#{table}.#{k}" if col.nil?
          sql2 = "#{col} = ?"
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
