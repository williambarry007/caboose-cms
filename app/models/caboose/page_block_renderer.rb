
class Caboose::PageBlockRenderer
  
  @page_block = nil
  
  # Renders the view for the given page block  
  def self.render(block)
    return "" if @page_block.nil?
    return @page_block.value    
  end
  
end
