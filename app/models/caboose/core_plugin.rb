class Caboose::CorePlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user, page)    
    return nav if user.nil?
        
    nav << { 'id' => 'logout'       , 'text' => 'Logout'     , 'href' => '/logout'     , 'modal' => false }    
    nav << { 'id' => 'my-account'   , 'text' => 'My Account' , 'href' => '/my-account' , 'modal' => true }
        
    #item = {
    #  'id' => 'profile',
    #  'text' => 'Profile',
    #  'children' => []
    #}    
    #item['children'] << { 'id' => 'my-account'   , 'text' => 'Edit Profile' , 'href' => '/my-account' , 'modal' => false }
    #item['children'] << { 'id' => 'logout'       , 'text' => 'Logout'       , 'href' => '/logout'     , 'modal' => false }    
    #nav << item
    
    item = {
      'id' => 'core',
      'text' => 'Settings',
      'children' => []
    }
    
    item['children'] << { 'id' => 'users'        , 'text' => 'Users'            , 'href' => '/admin/users'            , 'modal' => false } if user.is_allowed('users'          , 'view')
    item['children'] << { 'id' => 'roles'        , 'text' => 'Roles'            , 'href' => '/admin/roles'            , 'modal' => false } if user.is_allowed('roles'          , 'view')
    item['children'] << { 'id' => 'permissions'  , 'text' => 'Permissions'      , 'href' => '/admin/permissions'      , 'modal' => false } if user.is_allowed('permissions'    , 'view')
    item['children'] << { 'id' => 'variables'    , 'text' => 'Variables'        , 'href' => '/admin/settings'         , 'modal' => false } if user.is_allowed('settings'       , 'view')
    item['children'] << { 'id' => 'blocktypes'   , 'text' => 'Page Block Types' , 'href' => '/admin/page-block-types' , 'modal' => false } if user.is_allowed('pageblocktypes' , 'view')
        
    nav << item if item['children'].count > 0
    
    item = {
      'id' => 'content',
      'text' => 'Content',
      'children' => []
    }
    
    item['children'] << { 'id' => 'pages'        , 'text' => 'Pages'       , 'href' => '/admin/pages'        , 'modal' => false } if user.is_allowed('pages'       , 'view')
    item['children'] << { 'id' => 'posts'        , 'text' => 'Posts'       , 'href' => '/admin/posts'        , 'modal' => false } if user.is_allowed('posts'       , 'view')
    
    nav << item if item['children'].count > 0    
    if user.is_allowed('ab-variants','view')
      nav << { 'id' => 'ab_variants', 'text' => 'AB Testing', 'href' => '/admin/ab-variants', 'modal' => false }
    end
    return nav
  end
  
  #def self.admin_js
  #  return "
  #    $('#use_redirect_urls').click(function() {
  #      uru = $('#use_redirect_urls');
  #      val = (uru.html() == 'Enable' ? 1 : 0);        
  #      $.ajax({
  #        url: '/admin/settings/toggle-redirect-urls',
  #        data: 'val='+val,
  #        succes: function(resp) { uri.html(val == 1 ? 'Disable' : 'Enable'); }
  #      });
  #    });"
  #end

  def self.block_types(block_types)
    block_types << {
      :id => 'heading',
      :name => "Heading",
      :attributes => [        
        { name: 'text' , nice_name: 'Text' , type: 'text'  , default: '', width: 800, fixed_placeholder: false },
        { name: 'size' , nice_name: 'Size' , type: 'select', default: 1, width: 800, fixed_placeholder: false, options: ["1 - Largest", "2", "3", "4", "5", "6"]}        
      ]
    }
    block_types << {
      :id => 'richtext',
      :name => "Rich Text",
      :attributes => [        
        { name: 'text' , nice_name: 'Text' , type: 'richtext', default: '', width: 800, height: 400, fixed_placeholder: false }                
      ]
    }
    return block_types
  end

end
