
class Caboose::PageBlock < ActiveRecord::Base
  self.table_name = "page_blocks"
  
  belongs_to :page  
  attr_accessible :id, :page_id, :block_type, :sort_order, :name, :value
  
  def render(empty_text = nil)    
    str = self.send("render_#{self.block_type.downcase}", empty_text)
    #return empty_text if empty_text && (str.nil? || str.length == 0)
    return str
  end
  
  def render_richtext(empty_text = nil) return (self.value.nil? || self.value == "") && empty_text ? "<p>#{empty_text}</p>"   : self.value                end
  def render_p(empty_text = nil)        return (self.value.nil? || self.value == "") && empty_text ? "<p>#{empty_text}</p>"   : "<p>#{self.value}</p>"    end
  def render_h1(empty_text = nil)       return (self.value.nil? || self.value == "") && empty_text ? "<h1>#{empty_text}</h1>" : "<h1>#{self.value}</h1>"  end
  def render_h2(empty_text = nil)       return (self.value.nil? || self.value == "") && empty_text ? "<h2>#{empty_text}</h2>" : "<h2>#{self.value}</h2>"  end
  def render_h3(empty_text = nil)       return (self.value.nil? || self.value == "") && empty_text ? "<h3>#{empty_text}</h3>" : "<h3>#{self.value}</h3>"  end
  def render_h4(empty_text = nil)       return (self.value.nil? || self.value == "") && empty_text ? "<h4>#{empty_text}</h4>" : "<h4>#{self.value}</h4>"  end
  def render_h5(empty_text = nil)       return (self.value.nil? || self.value == "") && empty_text ? "<h5>#{empty_text}</h5>" : "<h5>#{self.value}</h5>"  end
  def render_h6(empty_text = nil)       return (self.value.nil? || self.value == "") && empty_text ? "<h6>#{empty_text}</h6>" : "<h6>#{self.value}</h6>"  end
    
end
