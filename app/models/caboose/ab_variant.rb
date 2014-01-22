# Class for A-B testing variants. A variant is a set of changes
# to the same element on a page. For example, a variant can be used
# to change the button text, or images displayed, or even more
# complicated behavior
class Caboose::AbVariant < ActiveRecord::Base
  self.table_name = "ab_variants"
  
  has_many :ab_options, :order => 'id', :dependent => :destroy
  has_many :ab_values, :dependent => :destroy
  attr_accessible :name, :analytics_name
  
  def random_option
    return nil if self.ab_options.nil? || self.ab_options.count == 0
    return self.ab_options.sample    
  end
  
end
