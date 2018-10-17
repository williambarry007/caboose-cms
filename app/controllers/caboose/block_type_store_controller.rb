module Caboose
  class BlockTypeStoreController < ApplicationController
        
    # @route GET /admin/block-type-store
    def admin_index
      return unless user_is_allowed('blocktypestore', 'add')
      @pager = PageBarGenerator.new(params, {
    		  'block_type_source_id' => '',
    		  'name_like'	           => '',
    		  'description_like'	   => ''    		  
    		},{
    		  'model'          => 'Caboose::BlockTypeSummary',
    	    'sort'			     => 'block_type_source_id, name',
    		  'desc'			     => false,
    		  'base_url'		   => '/admin/block-types/store',
    		  'use_url_params' => false
    	})
    	@block_type_summaries = @pager.items
    	render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/block-types/store/:block_type_summary_id/download
    def admin_download
      return unless user_is_allowed('blocktypestore', 'add')

      bts = BlockTypeSummary::find(params[:block_type_summary_id])
      bts.source.refresh(bts.name)

      resp = StdClass.new('success' => 'The block type has been downloaded successfully.')
      render :json => resp
    end
    
    # @route GET /admin/block-types/store/:block_type_summary_id
    def admin_details
      return unless user_is_allowed('blocktypestore', 'add')
      @block_type_summary = BlockTypeSummary::find(params[:block_type_summary_id])
      render :layout => 'caboose/admin'
    end
    
  end  
end
