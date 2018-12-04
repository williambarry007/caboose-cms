module Caboose
  class BlockTypeCategoriesController < ApplicationController

    # @route GET /admin/block-type-categories
    def admin_index
      redirect_to '/admin' and return if !logged_in_user.is_super_admin?
      @btc = BlockTypeCategory.where(:parent_id => nil).order(:sort_order).all
      render :layout => 'caboose/admin'
    end

    # @route GET /admin/block-type-categories/tree-options
    def admin_tree_options
      return unless user_is_allowed('pages', 'edit')
      render :json => BlockTypeCategory.tree
    end

    # @route GET /admin/block-type-categories/new
    def admin_new
      render :layout => 'caboose/admin'
    end

    # @route POST /admin/block-type-categories
    def admin_create
      render :json => false and return if !logged_in_user.is_super_admin?
      resp = StdClass.new
      if params[:name].blank?   
        resp.error = "Name is required."
      else
        par = BlockTypeCategory.where(:name => 'Content').first
        max = BlockTypeCategory.where(:parent_id => par.id).maximum(:sort_order) if par
        btc = BlockTypeCategory.new
        btc.name = params[:name]
        btc.parent_id = par.id if par
        btc.sort_order = max + 1 if max
        btc.save
        resp.redirect = "/admin/block-type-categories/#{btc.id}"
      end
      render :json => resp
    end

    # @route GET /admin/block-type-categories/:id
    def admin_edit
      redirect_to '/admin' and return if !logged_in_user.is_super_admin?
      @btc = BlockTypeCategory.find(params[:id])
      render :layout => 'caboose/admin'
    end

    # @route PUT /admin/block-type-categories/:id
    def admin_update
      render :json => false and return if !logged_in_user.is_super_admin?
    end

    # @route DELETE /admin/block-type-categories/:id
    def admin_delete
      render :json => false and return if !logged_in_user.is_super_admin?
    end

    # @route GET /admin/block-type-categories/:id/options
    def admin_options
    	btc = BlockTypeCategory.find(params[:id])
      options = params[:default] == 'yes' ? [{:text => 'Default', :value => 'Default'}] : []
      options << { 'value' => 'none', 'text' => "No Header" } if params[:none] == 'yes'
    	BlockType.joins(:block_type_site_memberships).where("block_type_site_memberships.site_id = ?",@site.id).where("block_type_site_memberships.block_type_id = block_types.id").where("block_types.block_type_category_id = ?",btc.id).reorder('block_types.description').all.each do |s|
        options << { 'value' => s.id, 'text' => s.description }
      end
    	render :json => options
    end
    		
  end  
end