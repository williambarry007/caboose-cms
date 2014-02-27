
class Caboose::PageBlockFieldValue < ActiveRecord::Base
  self.table_name = "page_block_field_values"

  belongs_to :page_block
  belongs_to :page_block_field

  has_attached_file :file, :path => '/uploads/:id.:extension'
  #do_not_validate_attachment_file_type :file
  has_attached_file :image, 
    :path => 'uploads/:id_:image_updated_at_:style.:extension', 
    :styles => {
      :tiny  => '160x120>',
      :thumb => '400x300>',
      :large => '640x480>'
    }
  #do_not_validate_attachment_file_type :image
    
  attr_accessible :id, :page_block_id, :page_block_field_id, :value
    
end
