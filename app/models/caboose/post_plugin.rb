class Caboose::PostPlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user, page)    
    return nav if user.nil? || !user.is_allowed('pages', 'view')
    
    item = {
      'id' => 'posts', 
      'text' => 'Posts',
      'children' => []      
      #'show_children_default' => true
    }
    item['children'] << { 
      'href' => "/admin/posts",
      'text' => 'New Post',
      'modal' => true 
    }
    if (user.is_allowed('posts', 'add'))
      item['children'] << { 
        'href' => "/admin/posts/new",
        'text' => 'New Post',
        'modal' => true 
      }
    end    
    nav << item
    return nav
  end
  
end
