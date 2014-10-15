module Caboose
  class Review < ActiveRecord::Base
    self.table_name = 'store_reviews'
    
    belongs_to :product
    
    attr_accessible :id,
      :product_id,
      :name,
      :rating,
      :content
  end
end