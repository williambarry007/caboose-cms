class Caboose::PageBlockRenderers::H6
  def self.render(block, empty_text = nil)
    return (block.value.nil? || block.value == "") && empty_text ? "<h6>#{empty_text}</h6>" : "<h6>#{block.value}</h6>"  
  end
end
