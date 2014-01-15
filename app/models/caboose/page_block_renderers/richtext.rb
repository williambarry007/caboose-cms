class Caboose::PageBlockRenderers::Richtext  
  def self.render(block, empty_text = nil)
    return (block.value.nil? || block.value == "") && empty_text ? "<p>#{empty_text}</p>"   : "<p>#{block.value}</p>"    
  end
end
