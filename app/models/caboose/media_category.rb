class Caboose::MediaCategory < ActiveRecord::Base

  self.table_name = "media_categories"  
  belongs_to :parent, :class_name => 'Caboose::MediaCategory'
  has_many :children, :class_name => 'Caboose::MediaCategory', :foreign_key => 'parent_id', :order => 'name'
  has_many :media_images, :class_name => 'Caboose::MediaImage', :order => 'name'
  has_many :media_files, :class_name => 'Caboose::MediaFile', :order => 'name'
  attr_accessible :id, :site_id, :parent_id, :name
  
  def self.top_image_category(site_id)
    return self.where("parent_id is null and site_id = ? and name = ?", site_id, 'Images').first
  end
  
  def self.top_file_category(site_id)
    return self.where("parent_id is null and site_id = ? and name = ?", site_id, 'Files').first
  end

end
