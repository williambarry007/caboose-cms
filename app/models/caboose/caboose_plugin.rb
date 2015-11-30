class Caboose::CaboosePlugin
 
  def self.page_content(str)
    return str    
  end
  
  def self.post_content(post)
    return post
  end
  
  def self.admin_nav(nav, user, page, site)
    return nav
  end
  
  def self.login_success(return_url, user_id)    
    return return_url
  end
  
end
