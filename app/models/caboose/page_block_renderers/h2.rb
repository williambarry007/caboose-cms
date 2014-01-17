class Caboose::PageBlockRenderers::H2
  def self.render(block, empty_text = nil)
    return (block.value.nil? || block.value == "") && empty_text ? "<h2>#{empty_text}</h2>" : "<h2>#{block.value}</h2>"
  end
end
