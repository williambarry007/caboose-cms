module Caboose
  class BlockCache
    
    attr_accessor :id,
      :page_id, 
      :parent_id,
      :block_type_id,
      :block_type_field_type,
      :sort_order,
      :name,
      :value,
      :file,
      :image,
      :children        
    
    def child_value(name)
      b = self.child(name)
      return nil if b.nil? 
      return b.image if b.block_type_field_type == 'image'
      return b.file  if b.block_type_field_type == 'file'
      return b.value
    end
    
    def child(name)
      self.children.each do |kid|
        return kid if kid.name == name
      end
      return nil    
    end
                                              
    #def render(block, options = nil)                    
    #  block = self.child(block) if block && block.is_a?(String)
    #  eval("CabooseBlockRendering::render_block_type_#{block.block_type_id}(block)")
    #end
     
    def initialize(b)
      self.id                     = b.id                    
      self.page_id                = b.page_id
      self.parent_id              = b.parent_id 
      self.block_type_id          = b.block_type_id
      self.block_type_field_type  = b.block_type ? b.block_type.field_type : nil
      self.sort_order             = b.sort_order
      self.name                   = b.name
      self.value                  = b.value
      self.file                   = BlockCacheFile.new(b.file)
      self.image                  = BlockCacheImage.new(b.image)
      self.children = b.children.collect{ |b2| BlockCache.new(b2) }
    end
    
    def page            
      return $page
    end
    
    def marshal_dump
      [
        self.id,
        self.page_id, 
        self.parent_id,
        self.block_type_id,
        self.block_type_field_type,
        self.sort_order,
        self.name,
        self.value,
        Marshal.dump(self.file),
        Marshal.dump(self.image),
        self.children.collect{ |b| Marshal.dump(b) }
      ]      
    end

    def marshal_load array
      self.id,
      self.page_id, 
      self.parent_id,
      self.block_type_id,
      self.block_type_field_type,
      self.sort_order,
      self.name,
      self.value,
      self.file,
      self.image,
      self.children = array
      
      self.file = Marshal.load(self.file)
      self.image = Marshal.load(self.image)
      self.children = self.children.collect{ |kid| Marshal.load(kid) }
    end
    
  end
end
