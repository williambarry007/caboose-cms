require 'uri'
require 'httparty'
require 'aws-sdk'

class Caboose::Media < ActiveRecord::Base

  self.table_name = "media"
  belongs_to :media_category
  has_attached_file :file, :path => ':caboose_prefixmedia/:id_:media_name.:extension'
  do_not_validate_attachment_file_type :file  
  has_attached_file :image, 
    :path => ':caboose_prefixmedia/:id_:media_name_:style.:extension',
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
    :sort_order,
    :processed,
    :image_content_type,
    :file_content_type
    
   has_attached_file :sample
   
   #before_post_process :set_content_dispositon
   #def set_content_dispositon
   #  self.sample.options.merge({ :s3_headers => { "Content-Disposition" => "attachment; filename=#{self.name}" }})
   #end

  def process
    #return if self.processed
    
    config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]    
    AWS.config({ 
      :access_key_id => config['access_key_id'],
      :secret_access_key => config['secret_access_key']  
    })
    bucket = config['bucket']
    bucket = Caboose::uploads_bucket && Caboose::uploads_bucket.strip.length > 0 ? Caboose::uploads_bucket : "#{bucket}-uploads"
        
    key = "#{self.media_category_id}_#{self.original_name}"    
    key = URI.encode(key.gsub(' ', '+'))    
    uri = "http://#{bucket}.s3.amazonaws.com/#{key}"    

    content_type = self.image_content_type || self.file_content_type

    if is_image?
      self.image = URI.parse(uri)
      self.image_content_type = content_type
    else
      self.file = URI.parse(uri)
      self.file_content_type = content_type
    end
    self.processed = true
    self.save

    # Set the content-type metadata on S3
    if !is_image?
      self.set_file_content_type(content_type)
    end

    # Remember when the last upload processing happened
    s = Caboose::Setting.where(:site_id => self.media_category.site_id, :name => 'last_upload_processed').first
    s = Caboose::Setting.create(:site_id => self.media_category.site_id, :name => 'last_upload_processed') if s.nil?
    s.value = DateTime.now.utc.strftime("%FT%T%z")
    s.save

    # Remove the temp file            
    bucket = AWS::S3::Bucket.new(bucket)
    obj = bucket.objects[key]
    obj.delete
         
  end
  
  def set_image_content_type(content_type)
    config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]    
    AWS.config({ 
      :access_key_id => config['access_key_id'],
      :secret_access_key => config['secret_access_key']  
    })
    s3 = AWS::S3.new
    bucket = s3.buckets[config['bucket']]
    ext = File.extname(self.image_file_name)[1..-1]
    self.image.styles.each do |style|
      k = "media/#{self.id}_#{self.name}_#{style}.#{ext}"
      bucket.objects[k].copy_from(k, :content_type => content_type) # a copy needs to be done to change the content-type
    end
  end
  
  def set_file_content_type(content_type)
    config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]    
    AWS.config({ 
      :access_key_id => config['access_key_id'],
      :secret_access_key => config['secret_access_key']  
    })
    s3 = AWS::S3.new
    bucket = s3.buckets[config['bucket']]
    ext = File.extname(self.file_file_name)[1..-1]
    # has_attached_file :file, :path => ':caboose_prefixmedia/:id_:media_name.:extension'
    k = "media/#{self.id}_#{self.name}.#{ext}"
    bucket.objects[k].copy_from(k, :content_type => content_type) # a copy needs to be done to change the content-type    
  end
  
  def download_image_from_url(url)
    self.image = URI.parse(url)
    self.processed = true
    self.save
  end
  
  def download_file_from_url(url)
    self.image = URI.parse(url)
    self.processed = true
    self.save
  end
  
  def api_hash
    {
      :id            => self.id,
      :name          => self.name,
      :original_name => self.original_name,
      :description   => self.description,
      :processed     => self.processed,
      :image_urls    => self.image_urls,
      :file_url      => self.file ? self.file.url : nil,
      :media_type    => self.is_image? ? 'image' : 'file'
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
  
  def duplicate(site_id)
    cat = Caboose::MediaCategory.top_category(site_id)
    m = Caboose::Media.create(      
      :media_category_id  => cat.id                  ,
      :name               => self.name               ,
      :description        => self.description        ,
      :original_name      => self.original_name      ,
      :image_file_name    => self.image_file_name    ,
      :image_content_type => self.image_content_type ,
      :image_file_size    => self.image_file_size    ,
      :image_updated_at   => self.image_updated_at   ,
      :file_file_name     => self.file_file_name     ,
      :file_content_type  => self.file_content_type  ,
      :file_file_size     => self.file_file_size     ,
      :file_updated_at    => self.file_updated_at    ,      
      :processed          => false
    )
    m.delay.download_image_from_url(self.image.url(:original)) if self.image
    m.delay.download_file_from_url(self.file.url) if self.file
    return m
  end
      
end
