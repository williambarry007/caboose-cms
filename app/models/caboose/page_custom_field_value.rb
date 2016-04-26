
class Caboose::PageCustomFieldValue < ActiveRecord::Base
  self.table_name = "page_custom_field_values"
      
  belongs_to :page
  belongs_to :page_custom_field  
  attr_accessible :id     ,
    :page_id              ,
    :page_custom_field_id ,    
    :key                  ,    
    :value                ,
    :sort_order

  def duplicate(page_id, page_custom_field_id)
    v = Caboose::PageCustomFieldValue.create(
      :page_id              => page_id,
      :page_custom_field_id => pag_custom_field_id,
      :key                  => self.key,
      :value                => self.value,
      :sort_order           => self.sort_order
    )
    return v
  end
      
end
