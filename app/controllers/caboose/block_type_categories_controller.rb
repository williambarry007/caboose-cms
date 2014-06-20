
module Caboose
  class BlockTypeCategoriesController < ApplicationController
    
    # GET /admin/block-type-categories/tree-options
    def admin_tree_options
      return unless user_is_allowed('pages', 'edit')
      render :json => BlockTypeCategory.tree
    end
    		
  end  
end
