class Caboose::PageBlockRenderers::H3
  def self.render(block, empty_text = nil)
    return (block.value.nil? || block.value == "") && empty_text ? "<h3>#{empty_text}</h3>" : "<h3>#{block.value}</h3>"
  end
end
