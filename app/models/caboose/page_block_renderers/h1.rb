class Caboose::PageBlockRenderers::H1
  def self.render(block, empty_text = nil)
    return (block.value.nil? || block.value == "") && empty_text ? "<h1>#{empty_text}</h1>" : "<h1>#{block.value}</h1>"
  end
end
