
class Caboose::FieldType < ActiveRecord::Base
  self.table_name = "field_types"

  belongs_to :block_type
  has_many :fields, :dependent => :destroy
  attr_accessible :id, 
    :block_type_id, 
    :name,
    :field_type, 
    :nice_name,
    :default, 
    :width,
    :height, 
    :fixed_placeholder, 
    :options,
    :options_function,
    :options_url
    
  def render_options(empty_text = nil)    
    return eval(self.options_function)    
  end
  
end
