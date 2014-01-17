class Caboose::PageBlockRenderers::H5
  def self.render(block, empty_text = nil)
    return (block.value.nil? || block.value == "") && empty_text ? "<h5>#{empty_text}</h5>" : "<h5>#{block.value}</h5>"  
  end
end
