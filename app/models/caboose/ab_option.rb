class Caboose::AbOption < ActiveRecord::Base

  belongs_to :ab_variant, dependent: :destroy

  attr_accessor :text

end
