class Caboose::RolePlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user, page)
    return nav if user.nil? || !user.is_allowed('roles', 'view')
       
    item = {
      'id' => 'roles',       
      'text' => 'Roles',
      'children' => []
    }
    if (user.is_allowed('roles', 'view'))
      item['children'] << {
        'href' => '/admin/roles', 
        'text' => 'View All Roles',
        'modal' => true
      }
    end
    if (user.is_allowed('roles', 'add'))
      item['children'] << {
        'href' => '/admin/roles/new', 
        'text' => 'New Role'
      }
    end
    nav << item
    return nav
  end
  
end
