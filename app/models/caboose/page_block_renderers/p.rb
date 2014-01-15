class Caboose::PageBlockRenderers::P
  def self.render(block, empty_text = nil)
    return (block.value.nil? || block.value == "") && empty_text ? "<p>#{empty_text}</p>"   : block.value                
  end
end
