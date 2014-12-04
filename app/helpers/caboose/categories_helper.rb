module Caboose
  module CategoriesHelper
    def root_category
      Caboose::Category.root
    end
    
    def top_level_categories
      Caboose::Category.top_level
    end
    
    def category_list(category=root_category)
      content_tag :ul, category_list_items(category)
    end
    
    def category_list_items(category)
      
      # Link to category
      link = link_to(category.name, "/admin/categories/#{category.id}")
      
      # Recursively find category children
      children = content_tag :ul, category.children.collect { |child| category_list_items(child) }.join.to_s.html_safe if category.children.any?
      
      # Return the list item
      content_tag :li, link.concat(children)
    end
    
    def category_select(form_name, category=root_category, selected_id=nil)
      
      # Collect all recursive options from specified category down
      options = category_options(category, selected_id)
      
      # Prepend the root category
      options.unshift([category.name, category.id])
      
      # Create select tag
      select_tag form_name, options_for_select(options)
    end
    
    def category_options(category, selected_id, prefix="")
      
      # Array to hold options
      options = Array.new
      
      # Recusively tterate over all child categories
      category.children.collect do |child|
        options << ["#{prefix} - #{child.name}", child.id]
        options.concat category_options(child, selected_id, "#{prefix} -")
      end
      
      # Return the options array
      return options
    end
    
    def category_checkboxes(top_categories, selected_ids = nil)
      str = "<ul>"
      top_categories.each do |cat|
        category_checkboxes_helper(cat, selected_ids, str)
      end
      str << "</ul>"
      return str
    end
    
    def category_checkboxes_helper(cat, selected_ids, str, prefix = "")
      str << "<li>"
      if cat.children && cat.children.count > 0
        str << "<input type='checkbox' id='cat_#{cat.id}' value='#{cat.id}'"
        str << " checked='true'" if selected_ids && selected_ids.include?(cat.id)
        str << "> <label for='#{cat.id}'><h3>#{cat.name}</h3></label>"
      else
        str << "<input type='checkbox' id='cat_#{cat.id}' value='#{cat.id}'"
        str << " checked='true'" if selected_ids && selected_ids.include?(cat.id)
        str << "> <label for='#{cat.id}'>#{cat.name}</label>"
      end
      cat.children.each do |cat2|
        str << "<ul>"
        category_checkboxes_helper(cat2, selected_ids, str, "#{prefix}&nbsp;&nbsp;")
        str << "</ul>"
      end
      str << "</li>"
    end
  end
end
