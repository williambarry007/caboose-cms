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

  # returns all of the variant options as an array 
  def getOptions
    @ab_options 
  end

  # adds a new option with the text "text"
  # option is given an id 
  def addOption(text)
    @ab_options.create(text: text, ab_variant: self)
  end

  # removes the option with option_id
  def removeOption(option_id)
    @ab_options.delete @ab_options.find(option_id)
  end
end
