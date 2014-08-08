class Caboose::MediaFile < ActiveRecord::Base

  self.table_name = "media_files"
  belongs_to :media_category
  has_attached_file :file, :path => 'media-files/:id.:extension'
  do_not_validate_attachment_file_type :file  
  attr_accessible :id, :media_category_id, :name, :description
  
  def api_hash
    {
      :id => self.id,
      :name => self.name,      
      :description => self.description,
      :url => self.file.url      
    }
  end

end
