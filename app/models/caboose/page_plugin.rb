class Caboose::PagePlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user, page)    
    return nav if user.nil? || !user.is_allowed('pages', 'view')
    
    item = {
      'id' => 'pages', 
      'text' => 'Pages',
      'children' => []
      #'show_children_default' => true
    }
      
    is_admin = user.is_allowed('all', 'all')
    actions = Caboose::Page.permissible_actions(user.id, page.id)
    if (actions.include?('edit') || is_admin)
    	item['children'] << { 'href' => "/pages/#{page.id}/sitemap"       , 'text' => 'Site Map This Page'  }
    	item['children'] << { 'href' => "/pages/#{page.id}/edit"          , 'text' => 'Edit Page Content'   }
    	item['children'] << { 'href' => "/pages/#{page.id}/edit-settings" , 'text' => 'Edit Page Settings'  }

    	#uru = session['use_redirect_urls'].nil? ? true : session['use_redirect_urls']
    	#item['children'] << { 'id' => 'use_redirect_urls', 'href' => '#', 'text' => '' + (uru ? 'Disable' : 'Enable') + ' Redirect Urls' }
    end
    if (user.is_allowed('pages', 'add') || is_admin)
      item['children'] << { 'href' => "/pages/new?parent_id=#{page.id}"  , 'text' => 'New Page' }
    end    
    nav << item
    return nav
  end
  
  def self.admin_js
    return "
      $('#use_redirect_urls').click(function() {
        uru = $('#use_redirect_urls');
        val = (uru.html() == 'Enable' ? 1 : 0);        
        $.ajax({
          url: '/admin/settings/toggle-redirect-urls',
          data: 'val='+val,
          succes: function(resp) { uri.html(val == 1 ? 'Disable' : 'Enable'); }
        });
      });"
  end
  
end
