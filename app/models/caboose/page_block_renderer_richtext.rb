
class Caboose::PageBlockRendererRichtext
  
  self.table_name = "page_blocks"
  
  belongs_to :page  
  attr_accessible :id, :page_id, :block_type, :sort_order, :name, :value
  
  @_renderer  
  def renderer
    if @_renderer.nil?
      @_renderer = "Caboose::PageBlock#{self.block_type.upcase}Renderer".constantize.new
      @_renderer.page_block = self
    end
    return @_renderer       
  end
  
  def render
    self.renderer.render
  end
  
  def content
    a = self.name.nil? || self.name.length == 0 ? '' : "<a name='#{self.name}'></a>"
    return "#{a}#{self.value}"          if self.block_type == 'richtext'
    return "#{a}<p>#{self.value}</p>"   if self.block_type == 'p'
    return "#{a}<h1>#{self.value}</h1>" if self.block_type == 'h1'
    return "#{a}<h2>#{self.value}</h2>" if self.block_type == 'h2'
    return "#{a}<h3>#{self.value}</h3>" if self.block_type == 'h3'
    return "#{a}<h4>#{self.value}</h4>" if self.block_type == 'h4'
    return "#{a}<h5>#{self.value}</h5>" if self.block_type == 'h5'
    return "#{a}<h6>#{self.value}</h6>" if self.block_type == 'h6'
    
    if self.block_type == 'posts'
      obj = Caboose::StdClass(JSON.parse(self.value))
      defaults = {
        'limit' => 10,
        'no_posts_message' => "<p>There are no posts right now.</p>",
        'invalid_category_message' => "<p>Invalid post category.</p>",
        'body_character_limit' => 0        
      }
      defaults.each { |k,v| obj[k] = v if obj[k].nil? }
      
      return obj.invalid_category_message if !Caboose::PostCategory.exists?(obj.category_id)
      cat = Caboose::PostCategory.find(obj.category_id)            
      posts = obj.limit == 0 ? cat.posts.reorder('created_at DESC') : cat.posts.reorder('created_at DESC').limit(obj.limit)      
      return obj.no_posts_message posts.nil? || posts.count == 0
      
      str = ""
      posts.each do |p|
        str = "<div class='post'>"
        str << "<h2>#{raw p.title}</h2>"
        str << "<div class='created_at'>#{p.created_at.strftime('%F %T')}</div>"
        str << "<div class='post_content'>"
        str << obj.body_character_limit > 0 ? Caboose.teaser_text(p.body, obj.body_character_limit) : p.body
        str << "</div>"
        str << "</div>"
      end
      
      assoc = cat
      if Caboose
      
      
      if Caboose::PostCategoryMembership.exists?(:post_category_id => cat.id)
        Caboose::PostCategoryMembership.where(:post_category_id => cat.id)
     
  end

end
