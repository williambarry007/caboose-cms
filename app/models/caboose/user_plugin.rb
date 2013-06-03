class Caboose::UserPlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user, page)
    return nav if user.nil? || !user.is_allowed('users', 'view')
    
    item = {
      'id' => 'users',
      'href' => '/admin/users', 
      'text' => 'Users',
      'children' => []
    }
    if (user.is_allowed('users', 'view'))
      item['children'] << {
        'href' => '/admin/users', 
        'text' => 'View All Users'
      }
    end
    if (user.is_allowed('users', 'add'))
      item['children'] << {
        'href' => '/admin/users/new', 
        'text' => 'New User'
      }
    end
    nav << item
    return nav
  end
  
end
