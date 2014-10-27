require 'uri'
require 'httparty'

class Caboose::MediaImage < ActiveRecord::Base

  self.table_name = "media_images"
  belongs_to :media_category  
  has_attached_file :image, 
    :path => 'media-images/:id_:style.:extension',
    :default_url => 'http://placehold.it/300x300',    
    :styles => {
      :tiny  => '150x200>',
      :thumb => '300x400>',
      :large => '600x800>'
    }
  do_not_validate_attachment_file_type :image  
  attr_accessible :id, :media_category_id, :name, :description

  def process
    
    config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]
    bucket = config['bucket']
    
    uri = "http://#{bucket}.s3.amazonaws.com/media-images/#{self.id}#{File.extname(self.name.downcase)}"
    puts "Processing #{uri}..."
    
    self.image = URI.parse(uri)
    self.save
  end
  
  def api_hash
    {
      :id => self.id,
      :name => self.name,
      :description => self.description,
      :tiny_url => self.image.url(:tiny),
      :thumb_url => self.image.url(:thumb),
      :large_url => self.image.url(:large),
      :original_url => self.image.url(:original)
    }
  end
  
end
