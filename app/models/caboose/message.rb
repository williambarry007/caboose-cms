module Caboose
  class Message
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    
    attr_accessor :name, :email, :body
    
    validates :name, :email, :body, presence: true
    validates :email, format: { :with => %r{.+@.+\..+} }, allow_blank: false
    
    def initialize(attributes={})
      attributes.each { |name, value| send("#{name}=", value) }
    end
    
    def persisted?
      false
    end
  end
end
