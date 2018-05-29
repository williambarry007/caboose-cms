class Caboose::MediaCategory < ActiveRecord::Base

  self.table_name = "media_categories"  
  belongs_to :parent, :class_name => 'Caboose::MediaCategory'
  has_many :children, :class_name => 'Caboose::MediaCategory', :foreign_key => 'parent_id', :order => 'name'
  has_many :media, :class_name => 'Caboose::Media', :order => 'sort_order'  
  attr_accessible :id, :site_id, :parent_id, :name
  
  def self.top_category(site_id)
    cat = self.where(:site_id => site_id, :parent_id => nil).first
    cat = self.create(:site_id => site_id, :parent_id => nil, :name => 'Media') if cat.nil?
    return cat    
  end
      
  def api_hash
    {
      :id        => self.id,
      :parent_id => self.parent_id,
      :site_id   => self.site_id,      
      :name      => self.name,
      :children  => self.children.collect { |child| child.api_hash },
      :media     => self.media.collect { |m| m.api_hash }      
    }
  end
  
  def self.tree(site_id)
    return self.where(:parent_id => nil, :site_id => site_id).reorder("name").all
  end
  
  def self.flat_tree(site_id, prefix = '-')
    arr = []
    self.tree(site_id).each do |cat|
      arr += self.flat_tree_helper(cat, prefix, '')
    end    
    return arr
  end
  
  def self.flat_tree_helper(cat, prefix, str)        
    cat.name = "#{str}#{cat.name}"
    if cat.name == "-&nbsp;&nbsp;Products"
      return []
    else
      arr = [{
        :id          => cat.id,
        :parent_id   => cat.parent_id,
        :site_id     => cat.site_id,      
        :name        => cat.name,
        :media_count => cat.media.count      
      }]
      cat.children.each do |cat2|
        arr += self.flat_tree_helper(cat2, prefix, "#{str}#{prefix}")
      end
      return arr
    end
  end
  
  def self.tree_hash(site_id)
    top_cat = self.where(:parent_id => nil, :site_id => site_id).first
    return self.tree_hash_helper(top_cat)        
  end
  
  def self.tree_hash_helper(cat)
    return {
      :id => cat.id,
      :name => cat.name,
      :media_count => cat.media.count,
      :children => (cat.name == 'Products' ? [] : cat.children.collect{ |kid| self.tree_hash_helper(kid) })
    }
  end
  
  def is_ancestor_of?(cat)    
    if cat.is_a?(Integer) || cat.is_a?(String)
      cat_id = cat.to_i
      return false if cat_id == -1
      cat = Caboose::MediaCategory.find(cat_id)
    end
    return false if cat.parent_id.nil?
    return false if cat.parent.nil?
    return true  if cat.parent.id == self.id
    return is_ancestor_of?(cat.parent)      
  end
  
  def is_child_of?(cat)
    cat = Caboose::MediaCategory.find(cat) if cat.is_a?(Integer)
    return cat.is_ancestor_of?(self)      
  end

end
