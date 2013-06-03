class Caboose::PermissionPlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user, page)
    return nav if user.nil? || !user.is_allowed('permissions', 'view')
        
    item = {
      'id' => 'permissions',
      'text' => 'Permissions',
      'children' => []
    }
    if (user.is_allowed('permissions', 'view'))
      item['children'] << {
        'href' => '/admin/permissions', 
        'text' => 'View All Permissions'
      }
    end
    if (user.is_allowed('permissions', 'add'))
      item['children'] << {
        'href' => '/admin/permissions/new', 
        'text' => 'New Permission'
      }
    end
    nav << item
    return nav
  end
 
end
