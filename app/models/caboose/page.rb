
class Caboose::Page < ActiveRecord::Base
  self.table_name = "pages"
  
  belongs_to :site, :class_name => 'Caboose::Site'
  belongs_to :parent, :class_name => 'Caboose::Page'
  has_many :children, :class_name => 'Caboose::Page', :foreign_key => 'parent_id', :order => 'sort_order, title'
  has_many :page_permissions  
  has_many :blocks, :order => 'sort_order'
  attr_accessible :id,
    :site_id,
    :parent_id, 
    :title, 
    :menu_title, 
    # :content, # Changed from column in pages to blocks
    :blocks,
    :slug, 
    :alias, 
    :uri, 
    :redirect_url, 
    :hide, 
    :content_format, 
    :custom_css, 
    :custom_js,
    :linked_resources, 
    :layout,
    :seo_title, # 70 chars
    :meta_keywords,
    :meta_description, # 156 chars
    :meta_robots, # Multi-select options: none, noindex, nofollow, nosnippet, noodp, noarchive
    :canonical_url,
    :facebook_description, # defaults to meta_description
    :googleplus_description # defaults to meta_description      
   
  CONTENT_FORMAT_HTML  = 1 
  CONTENT_FORMAT_TEXT  = 2
  CONTENT_FORMAT_RUBY  = 3

  def order_title
    return "" + menu_title + title unless menu_title.nil? || title.nil?
    return menu_title unless menu_title.nil?
    return title unless title.nil?
    return ""
  end
  
  def block
    Caboose::Block.where("page_id = ? and parent_id is null", self.id).first
  end
  
  def top_level_blocks
    Caboose::Block.where("page_id = ? and parent_id is null", self.id).reorder(:sort_order).all
  end
  
  #def content
  #  return "" if self.blocks.nil? || self.blocks.count == 0
  #  self.blocks.collect { |b| b.render }.join("\n")     
  #end
    
  def self.find_with_fields(page_id, fields)
    return self.where(:id => page_id).select(fields).first
  end

  def self.index_page(site_id)
    return self.where(:site_id => site_id, :parent_id => -1).first
  end
  
  def self.page_with_uri(host_with_port, uri, get_closest_parent = true)

    d = Caboose::Domain.where(:domain => host_with_port).first
    return false if d.nil?
    site_id = d.site_id    
    
    uri = uri.to_s.gsub(/^(.*?)\?.*?$/, '\1')
    uri.chop! if uri.end_with?('/')
    uri[0] = '' if uri.starts_with?('/')
      
    return self.index_page(site_id) if uri.length == 0

    page = false
    parts = uri.split('/')
      
    # See where to start looking
    page_ids = self.where(:site_id => site_id, :alias => parts[0]).limit(1).pluck(:id)
    page_id = !page_ids.nil? && page_ids.count > 0 ? page_ids[0] : false
    
    # Search for the page
    if page_id
      page_id = self.page_with_uri_helper(parts, 1, page_id)
    else
      parent_id = self.index_page(site_id)
      page_id = self.page_with_uri_helper(parts, 0, parent_id)
    end
    
    return false if page_id.nil?
        
    page = self.find(page_id)
    
    if (!get_closest_parent) # // Look for an exact match
      return false if page.uri != uri
    end
    return page   
  end
  
  def self.page_with_uri_helper(parts, level, parent_id)
    return parent_id if level >= parts.count
    slug = parts[level]   
    page_ids = self.where(:parent_id => parent_id, :slug => slug).limit(1).pluck(:id)
    return parent_id if page_ids.nil? || page_ids.count == 0    
    return self.page_with_uri_helper(parts, level+1, page_ids[0])       
  end
  
  def self.update_uri(page)
    #return if page.redirect_url && page.redirect_url.length > 0
    
    page.slug = self.slug(page.title) if page.slug.nil? || page.slug.strip.length == 0
    page.uri = page.alias && page.alias.strip.length > 0 ? page.alias : (page.parent ? "#{page.parent.uri}/#{page.slug}" : "#{page.slug}")
    page.uri[0] = '' if page.uri.starts_with?('/')
    page.save
    
    page.children.each { |p2| self.update_uri(p2) }     
  end
  
  def self.update_child_perms(page_id)
    page = self.find(page_id)
      
    viewers_ids   = Role.roles_with_page_permission(page_id, 'view').collect {|r| r.id }
    editors_ids   = Role.roles_with_page_permission(page_id, 'edit').collect {|r| r.id }
    approvers_ids = Role.roles_with_page_permission(page_id, 'approve').collect {|r| r.id }   
    
    self.update_child_perms_helper(page, viewer_ids, editor_ids, approver_ids)
  end
  
  def self.update_child_perms_helper(page, viewer_ids, editor_ids, approver_ids)
    self.update_authorized_for_action(page.id, 'view'     , viewer_ids)
    self.update_authorized_for_action(page.id, 'edit'     , editor_ids)
    self.update_authorized_for_action(page.id, 'approve'  , approver_ids)

    page.children.each do |kid|
      self.update_child_perms_helper(kid, viewer_ids, editor_ids, approver_ids)
    end
  end
  
  def self.update_authorized_for_action(page_id, action, roles)
    Caboose::PagePermission.where(:page_id => page_id, :action => action).destroy_all
    if (!roles.nil?)
      roles.each do |role|
        role_id = role.is_a?(Integer) ? role : role.id
        Caboose::PagePermission.create({
          :page_id => page_id,
          :role_id => role_id,
          :action => action
        })
      end
    end
    return true
  end
  
  def self.is_allowed(user, page_id, action)
    user = User.logged_out_user if user.nil?

    # Allow a user id to be sent instead of a user object
    user = User.find(user) if user.is_a?(Integer)
    user.role_ids = [Role.logged_out_role_id] if user.role_ids.nil?

    t = PagePermission.table    
    reqs = nil
    user.role_ids.each do |role_id|
      if (reqs.nil?)
        reqs = t[:role_id].eq(role_id)
      else
        reqs.or(t[:role_id].eq(role_id))
      end
    end 
    var params = { :page_id => page_id, :action => action }
    params << reqs if !reqs.nil?
    count = PagePermission.where(params).count
    
    return true if count > 0
    return false
  end
  
  def self.roles_with_permission(page_id, action)
    return Role.roles_with_page_permission(page_id, action)
  end
                
  def self.permissible_actions(user, page_id)
    if (user.is_a?(Integer))
      user = Caboose::User.find(user)
    end
    actions = []
    user.roles.each do |role|
      actions + Caboose::PagePermission.where({
          :role_id => role.id, 
          :page_id => page_id
        }).pluck(:action)
    end
    return actions.uniq
  end
  
  def self.page_ids_with_permission(user, action)
    if (user.is_a?(Integer))
      user = Caboose::User.find(user)
    end
    ids = []
    user.roles.each do |role|     
      ids + Caboose::PagePermission.where({
          :role_id => role.id,
          :action => action
        }).pluck(:page_id)
    end
    return ids.uniq
  end
  
  def self.crumb_trail(page)    
    page_id = page.nil? || !page ? 1 : (page.is_a?(Integer) ? page : page.id)
    
    arr = []
    self.crumb_trail_helper(page_id, arr)
    arr.reverse!
    
    trail = arr.collect do |row|
      Caboose::StdClass.new({
        'href' => !row.uri.nil? && row.uri.length > 0 ? row.uri : '/',
        'text' => !row.menu_title.nil? && row.menu_title.length > 0 ? row.menu_title : row.title
      })
    end
    return trail
  end
  
  def self.crumb_trail_helper(page_id, arr)
    return if page_id.nil? || page_id <= 0
    p = self.find_with_fields(page_id, [:parent_id, :title, :menu_title, :uri])   
    return if p.nil?
    arr << p
    self.crumb_trail_helper(p.parent_id, arr)
  end
  
  def self.subnav(page, use_redirect_urls = true, user = false)
    
    # Be nice and allow page ids to be sent
    if (page.is_a?(Integer)) 
      page = self.find_with_fields(page, [:title, :menu_title, :custom_sort_children])
    end
    
    block = Caboose::MenuBlock.new
    block.title = !page.menu_title.nil? && page.menu_title.length > 0 ? page.menu_title : page.title
    block.title_id = page.id
                   
    pages = self.select([:id, :title, :menu_title, :alias, :slug, :uri, :redirect_url, :sort_order]).where(:parent_id => page.id, :hide => false).reorder(:sort_order).all
    if (page.custom_sort_children)
      pages.sort! {|x,y| x.sort_order <=> y.sort_order }
    else
      pages.sort! {|x,y| x.order_title <=> y.order_title }
    end
      
    if (pages.nil? || pages.count == 0) # No children, go up a level  
      parent = self.find_with_fields(page.parent_id, [:title, :menu_title, :custom_sort_children])
      return block if parent.nil? # If we happen to be at the top page
      
      block.title = !parent.menu_title.nil? && parent.menu_title.length > 0 ? parent.menu_title : parent.title
      block.title_id = parent.id
      
      pages = self.select([
          :id, :title, :menu_title, :alias, :slug, :uri, :redirect_url, :sort_order
        ]).where(:parent_id => page.parent_id, :hide => false)
      if (parent.custom_sort_children)
        pages.sort! {|x,y| x.sort_order <=> y.sort_order }
      else
        pages.sort! {|x,y| x.order_title <=> y.order_title }    
      end
    end
    
    block.links = []
    pages.each do |p|
      link = Caboose::StdClass.new({
        'href' => !p.redirect_url.nil? && p.redirect_url.length > 0 ? p.redirect_url : p.uri,
        'text' => !p.menu_title.nil? && p.menu_title.length > 0 ? p.menu_title : p.title,
        'is_current' => p.id == page.id
      })
      if (!use_redirect_urls && self.is_allowed(user, p.id, 'edit'))
        link.href = row.uri
      end 
      block.links << link
    end    
    return block
  end
  
  def self.url(page_id)
    arr = []
    self.url_helper(page_id, arr)
    arr.reverse!
    
    path = []      
    arr.each do |row|
      if (row.alias.length > 0)
        path = [row.alias]
      elsif (row.slug.length > 0)
        path << row.slug
      end
    end
    return path.join('/')
  end
  
  def self.url_helper(page_id, arr)
    return if page_id <= 0
    
    p = self.find_with_fields(page_id, [:id, :parent_id, :title, :menu_title, :alias, :slug])
    return if p.nil?

    arr << p
    self.url_helper(p.parent_id, arr)
  end
  
  def self.slug(str)
    return str.downcase.gsub(' ', '-').gsub(/[^\w-]/, '')
  end
  
  def self.has_children(page_id)
    count = self.where(:parent_id => page_id).count
    return count > 0
  end
  
  def self.is_child(parent_id, child_id)
    pid = self.where(:id => child_id).limit(1).pluck(:parent_id)[0]
    return false if pid.nil? || pid <= 0
    return true if pid == parent_id
    return self.is_child(parent_id, pid)
  end

  def linked_resources_map
    resources = { js: [], css: [] }
    return resources if self.linked_resources.nil?
    self.linked_resources.each_line do |r|
      r.chomp!
      case r
      when /\.js$/
        resources[:js] << r
      when /\.css$/
        resources[:css] << r
      end
    end
    return resources
  end

end
