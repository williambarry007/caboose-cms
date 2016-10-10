
module Caboose        
  class Subscription < ActiveRecord::Base
    self.table_name  = 'store_subscriptions'
    self.primary_key = 'id'

    belongs_to :site
    belongs_to :variant
    has_many :user_subscriptions
    attr_accessible :id    ,      
      :site_id             ,
      :name                ,
      :description         ,
      :variant_id          ,
      :interval            ,
      :prorate             ,
      :prorate_method      ,
      :prorate_flat_amount ,
      :prorate_function    ,
      :start_on_day        ,
      :start_day           ,
      :start_month         ,
      :status      
      
    STATUS_ACTIVE = 'active'
    STATUS_INACTIVE = 'inactive'

    INTERVAL_MONTHLY = 'monthly'
    INTERVAL_YEARLY  = 'yearly'
    
    PRORATE_METHOD_FLAT       = 'flat'
    PRORATE_METHOD_PERCENTAGE = 'percentage'
    PRORATE_METHOD_CUSTOM     = 'custom'

  end
end

