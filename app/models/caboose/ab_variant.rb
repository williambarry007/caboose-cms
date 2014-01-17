# Class for A-B testing variants. A variant is a set of changes
# to the same element on a page. For example, a variant can be used
# to change the button text, or images displayed, or even more
# complicated behavior
class Caboose::AbVariant < ActiveRecord::Base
  self.table_name = "ab_variants"
  has_many :ab_options

  # name is the name of the variant
  # analytics name is a machine-readable name that will be send to GA
  attr_accessible :name, :analytics_name

  def get_session_option
    return "" unless self.ab_options
    opt = self.ab_options.sample
    return {text: opt.text, id: opt.id}
  end

end
