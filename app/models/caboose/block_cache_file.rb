
module Caboose
  class BlockCacheFile
        
    def initialize(file)
      @_url = file.url
    end
    
    def url(style = nil)
      return @_url      
    end
    
    def marshal_dump
      [@_url]
    end
    
    def marshal_load array
      @url = array.first
    end
    
  end
end
