class Caboose::CaboosePlugin
 
  def self.page_content_hook(str)
    return str    
  end
  
  def self.admin_nav_hook(arr)
    return arr
  end
  
  def self.admin_subnav_hook(arr)
    return arr
  end
  
end
