
module Caboose
  class BlockCacheImage
        
    def initialize(image)
      @urls = {}
      image.styles.each do |style|                  
        @urls[style[0].to_s] = image.url(style[0])
      end      
      #puts "--------------------------------------------"
      #puts "Caboose::BlockCacheImage.initialize"
      #puts "urls = #{@urls.inspect}"
      #puts "--------------------------------------------"
    end
    
    def url(style = nil)
      #puts "--------------------------------------------"
      #puts "Caboose::BlockCacheImage.url"
      #puts "urls = #{@urls.inspect}"
      #puts "--------------------------------------------"
      
      return @urls['thumb'] if style.nil?
      return @urls[style.to_s]
    end
    
    def marshal_dump
      arr = []
      if @urls && @urls.count > 0
        @urls.each do |k,v|                    
          arr << k
          arr << v
        end
      end      
      return arr
    end
    
    def marshal_load arr
      @urls = {}
      i = 0
      count = arr.count
      while i<count
        k = arr[i]
        @urls[k] = arr[i+1]
        i = i + 2        
      end      
      #puts "--------------------------------------------"
      #puts "Caboose::BlockCacheImage.marshal_load"
      #puts "urls = #{@urls.inspect}"
      #puts "--------------------------------------------"
    end
    
  end
end
