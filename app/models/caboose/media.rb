require 'uri'
require 'httparty'

class Caboose::Media < ActiveRecord::Base

  self.table_name = "media"
  belongs_to :media_category
  has_attached_file :file, :path => ':path_prefixmedia/:id_:media_name.:extension'
  do_not_validate_attachment_file_type :file  
  has_attached_file :image, 
    :path => ':path_prefixmedia/:id_:media_name_:style.:extension',
    :default_url => 'http://placehold.it/300x300',    
    :styles => {      
      :tiny  => '160x120>',
      :thumb => '400x300>',
      :large => '640x480>',
      :huge  => '1400x1050>'
    }
    #:s3_headers => lambda { |attachment| { "Content-Disposition" => "attachment; filename=\"#{attachment.name}\"" }}
  do_not_validate_attachment_file_type :image  
  attr_accessible :id, 
    :media_category_id, 
    :name,
    :original_name,
    :description, 
    :processed
    
   has_attached_file :sample
   
   #before_post_process :set_content_dispositon
   #def set_content_dispositon
   #  self.sample.options.merge({ :s3_headers => { "Content-Disposition" => "attachment; filename=#{self.name}" }})
   #end

  def process
    #return if self.processed
    
    config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]
    bucket = config['bucket']
        
    key = "#{self.media_category_id}_#{self.original_name}"
    key = URI.encode(key.gsub(' ', '+'))
    uri = "http://#{bucket}-uploads.s3.amazonaws.com/#{key}"
    
    image_extensions = ['.jpg', '.jpeg', '.gif', '.png', '.tif']
    ext = File.extname(key).downcase
    if image_extensions.include?(ext)    
      self.image = URI.parse(uri)
    else
      self.file = URI.parse(uri)
    end
    self.processed = true
    self.save
    
    # Set the downloadable file names
    #bucket = AWS::S3::Bucket.new(bucket)
    #['tiny', 'thumb', 'large'].each do |style|            
    #  obj = bucket.objects["media/#{self.id}_#{style}#{ext}"]
    #  obj.content_disposition = 'attachment; filename="' + self.name + '"'
    #  obj.store
    #end
           
    # Remove the temp file            
    bucket = AWS::S3::Bucket.new("#{bucket}-uploads")
    obj = bucket.objects[key]
    obj.delete
         
  end
  
  def api_hash
    {
      :id           => self.id,
      :name         => self.name,
      :description  => self.description,
      :processed    => self.processed,
      :image_urls   => self.image_urls,
      :file_url     => self.file ? self.file.url : nil,
      :media_type   => self.is_image? ? 'image' : 'file'
    }    
  end
  
  def is_image?
    image_extensions = ['.jpg', '.jpeg', '.gif', '.png', '.tif']
    ext = File.extname(self.original_name).downcase
    return true if image_extensions.include?(ext)
    return false    
  end
          
  def image_urls
    return nil if self.image.nil? || self.image.url(:tiny).starts_with?('http://placehold.it')
    return {
      :tiny_url     => self.image.url(:tiny),
      :thumb_url    => self.image.url(:thumb),
      :large_url    => self.image.url(:large),
      :original_url => self.image.url(:original)
    }
  end
  
  def self.upload_name(str)
    return '' if str.nil?
    return File.basename(str, File.extname(str)).downcase.gsub(' ', '-').gsub(/[^\w-]/, '')
  end
  
  def file_url
    return self.image.url(:original) if self.image && !self.image.url(:original).starts_with?('http://placehold.it')
    return self.file.url    
  end
  
  def reprocess_image
    self.image.reprocess!
  end
      
end
