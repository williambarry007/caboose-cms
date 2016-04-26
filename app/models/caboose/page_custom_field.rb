
class Caboose::PageCustomField < ActiveRecord::Base
  self.table_name = "page_custom_fields"
      
  belongs_to :site  
  attr_accessible :id  ,
    :site_id           ,
    :key               ,
    :name              ,
    :field_type        ,
    :default_value     ,
    :options           ,
    :sort_order
    
  FIELD_TYPE_TEXT = 'text'
  FIELD_TYPE_SELECT = 'select'
  FIELD_TYPE_CHECKBOX = 'checkbox'
  FIELD_TYPE_DATE = 'date'
  FIELD_TYPE_DATETIME = 'datetime'
  
  def duplicate(site_id)
    f = Caboose::PageCustomField.where(:site_id => site_id, :key => self.key).first
    if f.nil?      
      f = Caboose::PageCustomField.create(
        :site_id       => site_id            , 
        :key           => self.key           , 
        :name          => self.name          ,
        :field_type    => self.field_type    ,
        :default_value => self.default_value ,
        :options       => self.options       ,
        :sort_order    => self.sort_order
      )
    end
    return f
  end

end
