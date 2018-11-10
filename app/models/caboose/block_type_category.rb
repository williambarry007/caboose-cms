
class Caboose::BlockTypeCategory < ActiveRecord::Base
  self.table_name = "block_type_categories"

  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Caboose::BlockTypeCategory'  
  has_many :children, :foreign_key => 'parent_id', :class_name => 'Caboose::BlockTypeCategory', :dependent => :destroy, :order => :sort_order
  has_many :block_types
  attr_accessible :id,
    :parent_id,
    :name,
    :sort_order,
    :show_in_sidebar
    
  def self.layouts
    self.where("name = ? and parent_id is null", 'Layouts').reorder(:name).all
  end
  
  def self.content
    self.where("name = ? and parent_id is null", 'Content').reorder(:name).all
  end
  
  def self.rows
    cat = self.content
    return false if cat.nil?
    self.where("name = ? and parent_id = ?", 'Rows', cat.id).reorder(:name).all
  end
  
  def self.tree
    arr = []
    self.where("parent_id is null").reorder(:name).all.each do |cat|
      self.tree_helper(arr, cat, '')
    end
    return arr
  end
  
  def self.tree_helper(arr, cat, prefix)
    arr << { 'value' => cat.id, 'text' => "#{prefix}#{cat.name}" }
    cat.children.each do |kid|
      self.tree_helper(arr, kid, "#{prefix} - ")
    end
  end
  
end
