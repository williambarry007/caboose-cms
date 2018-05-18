
class Caboose::Page < ActiveRecord::Base
  self.table_name = "pages"
  
  belongs_to :site, :class_name => 'Caboose::Site'
  belongs_to :parent, :class_name => 'Caboose::Page'
  has_many :children, :class_name => 'Caboose::Page', :foreign_key => 'parent_id', :order => 'sort_order, title'
  has_many :page_permissions  
  has_many :blocks, :order => 'sort_order'
  has_many :page_tags, :class_name => 'Caboose::PageTag', :dependent => :delete_all, :order => 'tag'  
  has_one :page_cache
  has_many :page_custom_field_values
  attr_accessible :id      ,        
    :site_id               ,
    :parent_id             ,
    :title                 ,
    :menu_title            ,
    :slug                  ,
    :alias                 ,
    :uri                   ,
    :redirect_url          ,
    :hide                  ,
    :content_format        ,
    :custom_css            ,
    :custom_css_files      ,
    :custom_js             ,
    :custom_js_files       ,
    :linked_resources      ,
    :layout                ,
    :sort_order            ,
    :custom_sort_children  ,
    :seo_title             ,
    :meta_keywords         ,
    :meta_description      ,
    :meta_robots           ,
    :canonical_url         ,
    :fb_description        ,
    :gp_description        ,
    :status
   
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

  def is_published
    Caboose::Block.where(:page_id => self.id).where('status != ?','published').count == 0
  end

  def publish
    Caboose::Block.where(:page_id => self.id).where('status = ? OR status = ?','edited','added').all.each do |b|
      b.value = b.new_value if !b.new_value.blank?
      b.media_id = nil if b.new_media_id == 0
      b.media_id = b.new_media_id if !b.new_media_id.blank?
      b.sort_order = b.new_sort_order if !b.new_sort_order.blank?
      b.parent_id = b.new_parent_id if !b.new_parent_id.blank?
      b.status = 'published'
      b.new_value = nil
      b.new_media_id = nil
      b.new_sort_order = nil
      b.new_parent_id = nil
      b.save
    end
    deleted_blocks = Caboose::Block.where(:page_id => self.id, :status => 'deleted').pluck(:id)
    dids = deleted_blocks.blank? ? 0 : deleted_blocks
    Caboose::Block.where("id in (?) or parent_id in (?)",dids,dids).destroy_all
    Caboose::Block.where(:page_id => self.id, :status => nil).update_all(:status => 'published')
    self.status = 'published'
    self.save
  end

  def revert
    Caboose::Block.where(:page_id => self.id).where(:status => 'added').destroy_all
    Caboose::Block.where(:page_id => self.id).update_all("status = 'published', new_value = null, new_media_id = null, new_sort_order = sort_order, new_parent_id = null")
    self.status = 'published'
    self.save
  end
  
  def self.page_with_uri(host_with_port, uri, get_closest_parent = true)

    d = Caboose::Domain.where(:domain => host_with_port).first
    return false if d.nil? || d.under_construction == true
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
      
    viewer_ids   = Caboose::PagePermission.where(:page_id => page_id, :action => 'view'   ).all.collect{ |pp| pp.role_id }
    editor_ids   = Caboose::PagePermission.where(:page_id => page_id, :action => 'edit'   ).all.collect{ |pp| pp.role_id }
    approver_ids = Caboose::PagePermission.where(:page_id => page_id, :action => 'approve').all.collect{ |pp| pp.role_id }   
                              
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
    if roles
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
    user.role_ids = [Role.logged_out_role_id(user.site_id)] if user.role_ids.nil?

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
      acts = Caboose::PagePermission.where({
          :role_id => role.id, 
          :page_id => page_id
        }).pluq(:action)
      acts.each do |ac|
        actions << ac
      end
    end
    return actions
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
    
    ru = arr.last.redirect_url
    return ru if ru && ru.strip.length > 0

    path = []      
    arr.each do |row|
      if row.alias && row.alias.strip.length > 0        
        path = [row.alias]
      elsif row.slug && row.slug.strip.length > 0
        path << row.slug
      end
    end
    return "/#{path.join('/')}"
  end
  
  def self.url_helper(page_id, arr)
    return if page_id <= 0
    
    p = self.find_with_fields(page_id, [:id, :parent_id, :title, :menu_title, :alias, :slug, :redirect_url])
    return if p.nil?

    arr << p
    self.url_helper(p.parent_id, arr)
  end
  
  def url
    return Caboose::Page.url(self.id)
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
  
  def is_child_of?(parent_id)
    return Caboose::Page.is_child(parent_id, self.id)
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
  
  def head_title
    str = ""
    str << "#{self.title} | " if !self.title.nil? && self.title.strip.length > 0
    str << self.site.description if self.site && self.site.description
  end
  
  def self.pages_with_tag(parent_id, tag)
    self.includes(:page_tags).where(:hide => false, :parent_id => 1, :page_tags => { :tag => tag }).reorder('sort_order, title').all
  end
  
  def custom_field_value(key)
    fv = Caboose::PageCustomFieldValue.where(:page_id => self.id, :key => key).first
    if fv.nil?
      f = Caboose::PageCustomField.where(:site_id => self.site_id, :key => key).first
      return nil if f.nil?
      fv = Caboose::PageCustomFieldValue.create(:page_id => self.id, :page_custom_field_id => f.id, :key => key, :value => f.default_value, :sort_order => f.sort_order)
    end
    f = fv.page_custom_field
    return fv.value if f.nil?
    case f.field_type
      when Caboose::PageCustomField::FIELD_TYPE_TEXT     then return fv.value
      when Caboose::PageCustomField::FIELD_TYPE_SELECT   then return fv.value
      when Caboose::PageCustomField::FIELD_TYPE_CHECKBOX then return fv.value == '1'
      when Caboose::PageCustomField::FIELD_TYPE_DATE     then return fv.value ? Date.strptime(fv.value, "%Y-%m-%d") : nil
      when Caboose::PageCustomField::FIELD_TYPE_DATETIME then return fv.value ? DateTime.strptime(fv.value, "%Y-%m-%d %H:%i:%s") : nil
    end  
    return fv.value
  end
  
  def verify_custom_field_values_exist
    Caboose::PageCustomField.where(:site_id => self.site_id).all.each do |f|
      fv = Caboose::PageCustomFieldValue.where(:page_id => self.id, :page_custom_field_id => f.id).first                  
      Caboose::PageCustomFieldValue.create(:page_id => self.id, :page_custom_field_id => f.id, :key => f.key, :value => f.default_value, :sort_order => f.sort_order) if fv.nil?
    end
  end
  
  def duplicate(site_id, parent_id, duplicate_children = false, block_type_id = nil, child_block_type_id = nil)
    
    if parent_id.to_i == -1
      p = Caboose::Page.index_page(site_id)
      p.children.destroy_all        
      #if self.site_id != site_id
      #  self.page_tags.destroy_all    
      #  self.page_custom_field_values.destroy_all          
      #  self.page_permissions.destroy_all      
      #  self.block.destroy
      #end
    else
      p = Caboose::Page.create(:site_id => site_id, :parent_id => parent_id)
    end

    p.title                = "Copy of " + self.title                 
    p.menu_title           = self.menu_title            
    p.slug                 = self.slug                  
    p.alias                = self.alias                 
    p.uri                  = self.uri                   
    p.redirect_url         = self.redirect_url          
    p.hide                 = self.hide                  
    p.content_format       = self.content_format        
    p.custom_css           = self.custom_css            
    p.custom_js            = self.custom_js             
    p.linked_resources     = self.linked_resources      
    p.layout               = self.layout                
    p.sort_order           = self.sort_order            
    p.custom_sort_children = self.custom_sort_children  
    p.seo_title            = self.seo_title             
    p.meta_keywords        = self.meta_keywords         
    p.meta_description     = self.meta_description      
    p.meta_robots          = self.meta_robots           
    p.canonical_url        = self.canonical_url         
    p.fb_description       = self.fb_description        
    p.gp_description       = self.gp_description       
    p.save
    
    self.page_tags.each{ |tag| Caboose::PageTag.create(:page_id => p.id, :tag => tag.tag) }
    
    self.page_custom_field_values.each do |v|
      f = v.page_custom_field.duplicate(site_id)
      v.duplicate(p.id, f.id)      
    end
    
    self.page_permissions.each do |pp|
      pp.role.duplicate(site_id)      
      r = Caboose::Role.where(:site_id => site_id, :name => pp.role.name).first
      Caboose::PagePermission.create(:page_id => p.id, :role_id => r.id, :action => pp.action)
    end

    self.block.duplicate_page_block(site_id, p.id, block_type_id)
        
    if duplicate_children && !p.is_child_of?(self.id)
      self.children.each do |p2|
        p2.duplicate(site_id, p.id, duplicate_children, child_block_type_id, child_block_type_id)
      end
    end
  end
  
end
