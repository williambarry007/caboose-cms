module Caboose
  class GiftCardsController < Caboose::ApplicationController
    
    # @route GET /admin/gift-cards
    def admin_index
      return if !user_is_allowed('giftcards', 'view')      
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/gift-cards/json
    def admin_json
      return if !user_is_allowed('giftcards', 'view')
      
      pager = PageBarGenerator.new(params, {
          'site_id'             => @site.id,          
          'name'                => '',
          'code'                => '',      
          'card_type'           => '',
          'total_lte'           => '',
          'total_gte'           => '',
          'balance_lte'         => '',
          'balance_gte'         => '',
          'min_order_total_lte' => '',
          'min_order_total_gte' => '',
          'date_available_lte'  => '',
          'date_available_gte'  => '',
          'date_expires_lte'    => '',
          'date_expires_gte'    => '',
          'status'              => ''
    		},{
    		  'model'          => 'Caboose::GiftCard',
    	    'sort'			     => 'code',
    		  'desc'			     => false,
    		  'base_url'		   => "/admin/gift-cards",
    		  'use_url_params' => false
    	})
    	render :json => {
    	  :pager => pager,
    	  :models => pager.items
    	}
    end
    
    # @route GET /admin/gift-cards/:id/json
    def admin_json_single
      return if !user_is_allowed('giftcards', 'view')    
      gc = GiftCard.find(params[:id])      
      render :json => gc
    end
    
    # @route GET /admin/gift-cards/new
    def admin_new
      return if !user_is_allowed('giftcards', 'add')      
      render :layout => 'caboose/admin'
    end
    
    # @route POST /admin/gift-cards
    def admin_add
      return if !user_is_allowed('giftcards', 'add')
      
      resp = StdClass.new
      code = params[:code].strip
      
      if code.length == 0
        resp.error = "A valid code is required."
      elsif GiftCard.where(:code => code).exists?
        resp.error = "A gift card with that code already exists."
      else
        gc = GiftCard.new(
          :site_id => @site.id,
          :code    => code,
          :status  => GiftCard::STATUS_INACTIVE              
        )
        resp.success = gc.save
        resp.new_id = gc.id
        resp.redirect = "/admin/gift-cards/#{gc.id}"
      end
      
      render :json => resp        
    end
    
    # @route POST /admin/gift-cards/bulk
    def admin_bulk_add
      return if !user_is_allowed('sites', 'add')
      
      resp = Caboose::StdClass.new
      i = 0
      CSV.parse(params[:csv_data].strip).each do |row|        
        if row[0].nil? || row[0].strip.length == 0        
          resp.error = "Code not defined on row #{i+1}."        
        end
        i = i + 1
      end
      
      if resp.error.nil?
        CSV.parse(params[:csv_data]).each do |row|
          Caboose::GiftCard.create(
            :site_id  => @site.id,
            :code => row[0].strip,            
            :status => GiftCard::STATUS_INACTIVE                        
          )
        end
        resp.success = true
      end
      
      render :json => resp
    end
  
    # @route GET /admin/gift-cards/:id
    def admin_edit
      return if !user_is_allowed('giftcards', 'edit')
      @gift_card = GiftCard.find(params[:id])
      render :layout => 'caboose/admin'
    end

    # @route PUT /admin/gift-cards/:id
    def admin_update
      return if !user_is_allowed('giftcards', 'edit')
      
      resp = Caboose::StdClass.new
      gc = GiftCard.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name
          when 'site_id'         then gc.site_id         = value                 
          when 'name'            then gc.name            = value
          when 'code'            then gc.code            = value
          when 'card_type'       then gc.card_type       = value
          when 'total'           then gc.total           = value
          when 'balance'         then gc.balance         = value
          when 'min_order_total' then gc.min_order_total = value
          when 'date_available'  then gc.date_available  = DateTime.strptime(value, '%m/%d/%Y')
          when 'date_expires'    then gc.date_expires    = DateTime.strptime(value, '%m/%d/%Y')
          when 'status'          then gc.status          = value                            
        end
      end          
      resp.success = save && gc.save
      render :json => resp
    end
    
    # @route PUT /admin/gift-cards/bulk
    def admin_bulk_update
      return unless user_is_allowed_to 'edit', 'sites'
    
      resp = Caboose::StdClass.new    
      gift_cards = params[:model_ids].collect{ |gc_id| GiftCard.find(gc_id) }
    
      save = true
      params.each do |k,v|
        case k
          when 'site_id'         then gift_cards.each{ |gc| gc.site_id         = v }                 
          when 'name'            then gift_cards.each{ |gc| gc.name            = v }
          when 'code'            then gift_cards.each{ |gc| gc.code            = v }
          when 'card_type'       then gift_cards.each{ |gc| gc.card_type       = v }
          when 'total'           then gift_cards.each{ |gc| gc.total           = v }
          when 'balance'         then gift_cards.each{ |gc| gc.balance         = v }
          when 'min_order_total' then gift_cards.each{ |gc| gc.min_order_total = v }            
          when 'date_available'  then gift_cards.each{ |gc| gc.date_available  = DateTime.strptime(v, '%m/%d/%Y') }
          when 'date_expires'    then gift_cards.each{ |gc| gc.date_expires    = DateTime.strptime(v, '%m/%d/%Y') }
          when 'status'          then gift_cards.each{ |gc| gc.status          = v }                      
        end        
      end
      gift_cards.each{ |gc| gc.save }
    
      resp.success = true
      render :json => resp
    end
    
    # @route DELETE /admin/gift-cards/:id
    def admin_delete
      return if !user_is_allowed('giftcards', 'delete')
      GiftCard.find(params[:id]).destroy
      render :json => Caboose::StdClass.new({
        :redirect => '/admin/gift-cards'
      })
    end
    
    # @route DELETE /admin/gift-cards/:id/bulk    
    def admin_bulk_delete
      return if !user_is_allowed('sites', 'delete')
      
      resp = Caboose::StdClass.new
      params[:model_ids].each do |gc_id|
        GiftCard.find(gc_id).destroy
      end
      resp.success = true
      render :json => resp
    end
        
    # @route GET /admin/gift-cards/status-options
    def admin_status_options
      return if !user_is_allowed('categories', 'view')
      statuses = [      
        GiftCard::STATUS_INACTIVE,
        GiftCard::STATUS_ACTIVE,
        GiftCard::STATUS_EXPIRED
      ]        
      options = statuses.collect{ |s| { 'text' => s, 'value' => s }}       
      render :json => options
    end
        
    # @route GET /admin/gift-cards/card-type-options
    def admin_card_type_options
      return if !user_is_allowed('categories', 'view')
      types = [
        GiftCard::CARD_TYPE_AMOUNT,
        GiftCard::CARD_TYPE_PERCENTAGE,
        GiftCard::CARD_TYPE_NO_SHIPPING,
        GiftCard::CARD_TYPE_NO_TAX,
      ]        
      options = types.collect{ |s| { 'text' => s, 'value' => s }}       
      render :json => options            
    end
    
  end
end
