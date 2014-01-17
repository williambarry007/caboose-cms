class Caboose::PageBlockRenderers::H4
  def self.render(block, empty_text = nil)
    return (block.value.nil? || block.value == "") && empty_text ? "<h4>#{empty_text}</h4>" : "<h4>#{block.value}</h4>"
  end
end
