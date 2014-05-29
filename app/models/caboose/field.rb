
class Caboose::Field < ActiveRecord::Base
  self.table_name = "fields"

  belongs_to :block
  belongs_to :field_type  
  has_one :child_block, :class_name => 'Caboose::Block'

  has_attached_file :file, :path => '/uploads/:id.:extension'
  do_not_validate_attachment_file_type :file
  has_attached_file :image, 
    :path => 'uploads/:id_:style.:extension', 
    :styles => {
      :tiny  => '160x120>',
      :thumb => '400x300>',
      :large => '640x480>'
    }
  do_not_validate_attachment_file_type :image
    
  attr_accessible :id, :block_id, :field_type_id, :value, :child_block_id
  
  after_initialize do |f|
    # Do whatever we need to do to set the value to be correct for the field type we have.
    # Most field types are fine with the raw value in the database
    if f.field_type.nil?
      f.field_type = 'text'
      f.save
    end
    case f.field_type.field_type
      when 'checkbox' then f.value = (f.value == 1 || f.value == '1' || f.value == true ? true : false)
    end
  end
  
  before_save :caste_value
  def caste_value  
    case self.field_type.field_type
      when 'checkbox'
        if self.value.nil? then self.value = false
        else self.value = (self.value == 1 || self.value == '1' || self.value == true ? 1 : 0)
        end
    end
  end

end
