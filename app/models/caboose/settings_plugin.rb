class Caboose::SettingsPlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user, page)
    return nav if user.nil? || !user.is_allowed('settings', 'view')
       
    item = {
      'id' => 'settings',       
      'text' => 'Settings',
      'children' => []
    }
    if (user.is_allowed('settings', 'view'))
      item['children'] << {
        'href' => '/admin/settings',
        'text' => 'View All Settings'
      }
    end
    if (user.is_allowed('settings', 'add'))
      item['children'] << {
        'href' => '/admin/settings/new', 
        'text' => 'New Setting'
      }
    end
    nav << item
    return nav
  end
  
end
