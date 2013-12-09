module Caboose
  module ProductsHelper
    
    def average_review(product_id)
      all_reviews = Review.where(:product_id => product_id)
      score = 0
      count = 0
      all_reviews.each do |r|
        if r.rating && r.rating != 0
          score += r.rating
          count += 1
        end
      end
      return score/count if count > 0
      return 0
    end
    
  end
end
