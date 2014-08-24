module Caboose
  class Crumbtrail

    @_crumbtrail = []
    
    def self.add(url, text = nil)
      #@_crumbtrail = []
      if url.is_a?(Hash)
        url.each do |url2, text2|
          @_crumbtrail << [url2, text2]
        end
      else
        @_crumbtrail << [url, text]
      end
    end
    
    def self.print(url = nil, text = nil)
      if url
        self.add(url, text)
      end
      
      str = "<ul id='crumbtrail'>"
      count = @_crumbtrail.count
      @_crumbtrail.each_with_index do |arr, i|
        is_last = i == (count - 1)
        str << "<li#{ is_last ? " class='current'" : '' }><a href='#{ is_last ? '#' : arr[0] }'><span>#{arr[1]}</span></a></li>"
      end
      str << "</ul>"
      return str
    end
    
  end
end
