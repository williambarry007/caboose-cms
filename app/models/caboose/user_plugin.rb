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
        'text' => 'View All Users',
        'modal' => true,
      }
    end
    if (user.is_allowed('users', 'add'))
      item['children'] << {
        'href' => '/admin/users/new', 
        'text' => 'New User',
        'modal' => true,
      }
    end
    nav << item
    return nav
  end
  
end
