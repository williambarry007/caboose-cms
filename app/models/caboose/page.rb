
class Caboose::Page < ActiveRecord::Base
  self.table_name = "pages"
  
  belongs_to :parent, :class_name => "Page"
  has_many :children, :class_name => "Page", :foreign_key => 'parent_id'    
  has_many :page_permissions
  attr_accessible :parent_id, 
    :title, 
    :menu_title, 
    :content, 
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
    
  def self.find_with_fields(page_id, fields)
    return self.where(:id => page_id).select(fields).first
  end

  def self.index_page
    return self.where(:parent_id => -1).first
  end
  
  def self.page_with_uri(uri, get_closest_parent = true)

    uri = uri.to_s.gsub(/^(.*?)\?.*?$/, '\1')
    uri.chop! if uri.end_with?('/')
    uri[0] = '' if uri.starts_with?('/')
      
    return self.index_page if uri.length == 0

    page = false
		parts = uri.split('/')
			
		# See where to start looking
		page_ids = self.where(:alias => parts[0]).limit(1).pluck(:id)
		page_id = !page_ids.nil? && page_ids.count > 0 ? page_ids[0] : false
		
		# Search for the page
		if (page_id)
		  page_id = self.page_with_uri_helper(parts, 1, page_id)
		else
		  parent_id = self.index_page
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
	
	def self.update_child_uris(page_id)
		page = self.find(page_id)
		parent = self.find(page.parent_id)
		parent_uri = parent.nil? ? '/' : parent.uri
		self.update_child_uris_helper(ppage, parent_uri)
	end

	def self.update_child_uris_helper(page, parent_uri)
		return if page.redirect_url.length > 0
		
		slug = page.slug
		if (slug.trim.length == 0)
			slug = self.get_slug(page.title)
			self.update_detail_field(page.id, 'slug', slug)
		end
		
		slug = page.slug.trim.length > 0 ? page.slug : self.get_slug(page.title)
		
		uri= "#{parent_uri}/#{slug}"
		if (page.alias.length > 0)
		  uri = "/#{page.alias}" 
		elsif (self.is_top_level(page.parent_id))
		  uri = "/#{page.slug}"
		end
		self.update_detail_field(page.id, 'uri', uri)
		
		page.children.each do |kid|
		  self.update_child_uris_helper(kid, uri)
		end
	end
	
	def self.update_child_perms(page_id)
		page = self.find(page_id)
			
		viewers 	= Role.roles_with_page_permission(page_id, 'view')
		editors 	= Role.roles_with_page_permission(page_id, 'edit')
		approvers	= Role.roles_with_page_permission(page_id, 'approve')		
		viewer_ids 		= viewers.collect {|r| r.id }
		editor_ids 		= editors.collect {|r| r.id }
		approver_id 	= approvers.collect {|r| r.id }
		
		self.update_child_perms_helper(page, viewer_ids, editor_ids, approver_ids)
	end
	
	def self.update_child_perms_helper(page, viewer_ids, editor_ids, approver_ids)
		self.update_authorized_for_action(page.id, 'view'		  , viewer_ids)
		self.update_authorized_for_action(page.id, 'edit'		  , editor_ids)
		self.update_authorized_for_action(page.id, 'approve'	, approver_ids)

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
		page_id = page.is_a?(Integer) ? page : page.id
		
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
	  pid = self.where(:page_id => child_id).first.pluck(:parent_id)
		return false if pid <= 0
		return true if pid == parent_id
		return self.is_child(parent_id, pid)
	end

end
