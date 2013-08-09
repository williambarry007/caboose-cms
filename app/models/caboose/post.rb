
class Caboose::Post < ActiveRecord::Base
  self.table_name = "posts"
  belongs_to :category
  attr_accessible :id, :category_id, :title, :body, :published
  has_attached_file :image, 
    :path => 'posts/:id_:style.:extension', 
    :styles => {
      :tiny  => '75x75>',
      :thumb => '150x150>',
      :large => '400x400>'
    }

end
