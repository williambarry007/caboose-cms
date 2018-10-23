
module Caboose
  class BlockTypeCategoriesController < ApplicationController
    
    # @route GET /admin/block-type-categories/tree-options
    def admin_tree_options
      return unless user_is_allowed('pages', 'edit')
      render :json => BlockTypeCategory.tree
    end

    # @route GET /admin/block-type-categories/:id/options
    def admin_options
    	btc = BlockTypeCategory.find(params[:id])
    	options = BlockType.joins(:block_type_site_memberships).where("block_type_site_memberships.site_id = ?",@site.id).where("block_type_site_memberships.block_type_id = block_types.id").where("block_types.block_type_category_id = ?",btc.id).reorder('block_types.description').all.collect { |s| { 'value' => s.id, 'text' => s.description }}
    	render :json => options
    end
    		
  end  
end
