
class Caboose::PageBlockFieldValue < ActiveRecord::Base
  self.table_name = "page_block_field_values"

  belongs_to :page_block
  belongs_to :page_block_field

  has_attached_file :file, :path => '/uploads/:id.:extension'
  do_not_validate_attachment_file_type :file
  has_attached_file :image, 
    :path => 'uploads/:id_:image_updated_at_:style.:extension', 
    :styles => {
      :tiny  => '160x120>',
      :thumb => '400x300>',
      :large => '640x480>'
    }
  do_not_validate_attachment_file_type :image
    
  attr_accessible :id, :page_block_id, :page_block_field_id, :value
  
  after_initialize do |fv|
    # Do whatever we need to do to set the value to be correct for the field type we have.
    # Most field types are fine with the raw value in the database                    
    case fv.page_block_field.field_type       
      when 'checkbox' then fv.value = (fv.value == 1 || fv.value == '1' || fv.value == true ? true : false)
    end
  end
  
  before_save :caste_value
  def caste_value  
    case self.page_block_field.field_type
      when 'checkbox'
        if self.value.nil? then self.value = false
        else self.value = (self.value == 1 || self.value == '1' || self.value == true ? 1 : 0)
        end
    end
  end

end
