
var Pager = function(params) { this.init(params); }
Pager.prototype = {
  
  base_url:       '',
  sort:           '',
  desc:           false,
  item_count:     0,  		
  items_per_page: 10,
  page:           1,		  		
  use_url_params: false,
  
  init: function(params)
  {
    for (var thing in params)
      this[thing] = params[thing];
  }
  
  // Paramters:
  // cols: Hash { key = sort field, value = text to display }
  sortable_table_headings: function(cols)
  {
    var that = this;
    this.base_url += this.base_url.indexOf('?') > -1 ? '&' : '?';          
    var str = '';
      
    var tr = $('<tr/>');        
    $.each(cols, function(sort, text) {
      var arrow = that.sort == sort ? (that.desc == 1 ? ' &uarr;' : ' &darr;') : '';            
      var link = that.base_url + 'sort=' + sort + '&desc=' + (that.desc == 1 ? '0' : '1');
      tr.append($('<th/>').append(      
      str += "<th><a href='#{link}'>#{text}#{arrow}</a></th>\n"
    	end
    	return str  	
    end
   
    def generate(summary = true)
  	    	  
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
  		str << "<p>Results: showing page #{page} of #{total_pages}</p>\n" if summary
  		
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
  	  
};
