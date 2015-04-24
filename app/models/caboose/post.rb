
class Caboose::Post < ActiveRecord::Base
  self.table_name = "posts"
  
  has_many :post_category_memberships
  has_many :post_categories, :through => :post_category_memberships
  belongs_to :site
  
  attr_accessible :id,        
    :site_id     ,
    :title       ,
    :subtitle    ,
    :author      ,
    :body        ,
    :preview     ,
    :hide        ,
    :image_url   ,
    :published   ,
    :created_at  ,
    :updated_at
    
  has_attached_file :image, 
    :path => ':path_prefixposts/:id_:style.:extension',
    :default_url => 'http://placehold.it/300x300',
    :styles => {
      :tiny  => '75x75>',
      :thumb => '150x150>',
      :large => '400x400>'
    }
  do_not_validate_attachment_file_type :image
  
  def block
    Caboose::Block.where("post_id = ? and parent_id is null", self.id).first
  end
  
  def top_level_blocks
    Caboose::Block.where("post_id = ? and parent_id is null", self.id).reorder(:sort_order).all
  end
  
  def self.slug(str)    
    return str.downcase.gsub(' ', '-').gsub(/[^\w-]/, '')        
  end
  
  def self.uri(post)
    str = "/posts/#x{post.created_at.strftime('%Y/%m/%d')}/#{post.slug}"
    i = 2
    while Caboose::Post.where("site_id = ? and id <> ? and uri = ?", post.site_id, post.id, str).exists?
      str = "/posts/#{post.created_at.strftime('%Y/%m/%d')}/#{post.slug}-#{i}"
      i = i + 1
    end      
    return str
  end
  
  def set_slug_and_uri(str)
    d = self.created_at.strftime('%Y/%m/%d')
    s = Caboose::Post.slug(str)
    new_slug = "#{s}"
    new_uri = "/posts/#{d}/#{new_slug}"
    i = 2
    while Caboose::Post.where("site_id = ? and id <> ? and uri = ?", self.site_id, self.id, new_uri).exists?
      new_slug = "#{s}-#{i}"
      new_uri = "/posts/#{d}/#{new_slug}"      
      i = i + 1
    end
    self.slug = new_slug
    self.uri = new_uri
    self.save        
  end  

end
