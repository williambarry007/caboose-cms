
class Caboose::PageBlock < ActiveRecord::Base
  self.table_name = "page_blocks"
  
  belongs_to :page  
  attr_accessible :id, :page_id, :block_type, :sort_order, :name, :value
  
  def render(empty_text = nil)    
    str = self.send("render_#{self.block_type.downcase}")
    return empty_text if empty_text && (str.nil? || str.length == 0)
    return str
  end
  
  def render_richtext() return self.value               end
  def render_p()        return "<p>#{self.value}</p>"   end
  def render_h1()       return "<h1>#{self.value}</h1>" end
  def render_h2()       return "<h2>#{self.value}</h2>" end
  def render_h3()       return "<h3>#{self.value}</h3>" end
  def render_h4()       return "<h4>#{self.value}</h4>" end
  def render_h5()       return "<h5>#{self.value}</h5>" end
  def render_h6()       return "<h6>#{self.value}</h6>" end
    
  def render_posts
    return ""    
    #obj = Caboose::StdClass(JSON.parse(self.value))
    #defaults = {
    #  'limit' => 10,
    #  'no_posts_message' => "<p>There are no posts right now.</p>",
    #  'invalid_category_message' => "<p>Invalid post category.</p>",
    #  'body_character_limit' => 0        
    #}
    #defaults.each { |k,v| obj[k] = v if obj[k].nil? }
    #
    #return obj.invalid_category_message if !Caboose::PostCategory.exists?(obj.category_id)
    #cat = Caboose::PostCategory.find(obj.category_id)            
    #posts = obj.limit == 0 ? cat.posts.reorder('created_at DESC') : cat.posts.reorder('created_at DESC').limit(obj.limit)      
    #return obj.no_posts_message posts.nil? || posts.count == 0
    #
    #str = ""
    #posts.each do |p|
    #  str = "<div class='post'>"
    #  str << "<h2>#{raw p.title}</h2>"
    #  str << "<div class='created_at'>#{p.created_at.strftime('%F %T')}</div>"
    #  str << "<div class='post_content'>"
    #  str << obj.body_character_limit > 0 ? Caboose.teaser_text(p.body, obj.body_character_limit) : p.body
    #  str << "</div>"
    #  str << "</div>"
    #end
  end
end
