require 'uri'

class Caboose::MediaImage < ActiveRecord::Base

  self.table_name = "media_images"
  belongs_to :media_category  
  has_attached_file :image, 
    :path => 'media-images/:id_:style.:extension',
    :default_url => "#{Caboose::cdn_domain}/media-images/default_user_image.jpg",    
    :styles => {
      :tiny  => '150x200>',
      :thumb => '300x400>',
      :large => '600x800>'
    }
  do_not_validate_attachment_file_type :image  
  attr_accessible :id, :media_category_id, :name, :description

  def process
    puts "http://#{Caboose::cdn_domain}/media-images/#{self.id}#{File.extname(self.name.downcase)}"
    self.image = URI.parse("http://#{Caboose::cdn_domain}/media-images/#{self.id}#{File.extname(self.name.downcase)}")
    self.save    
  end
  
end
