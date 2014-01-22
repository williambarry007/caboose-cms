module Caboose
  class AbTesting
    
    @@session_id = nil
    
    # Sets the ab_variants for the user's session
    def self.init(session_id)
      @@session_id = "#{session_id}"
      AbVariant.all.each { |var| self.create_ab_value(var) }
    end
    
    # Ensure that an ab_value exists for the given session and variant 
    def self.create_ab_value(var)      
      if AbValue.where(:session_id => @@session_id, :ab_variant_id => var.id).exists?
        return AbValue.where(:session_id => @@session_id, :ab_variant_id => var.id).first
      end
      return AbValue.create(:session_id => @@session_id, :ab_variant_id => var.id, :ab_option_id  => var.random_option.id)      
    end
   
    # Get this session's ab_value value for the variant with the given analytics name
    def self.[](analytics_name)
      return self.value_for_name(analytics_name)      
    end
 
    def self.value_for_name(analytics_name)
      return nil if !AbVariant.where(:analytics_name => analytics_name).exists?  
      var = AbVariant.where(:analytics_name => analytics_name).first 
      abv = self.create_ab_value(var) 
      return abv.ab_option.value
    end      

    # Get the analytics string
    def self.analytics_string
      arr = AbValue.where(:session_id => @@session_id).all.collect { |abv| abv.keyval }
      return "|#{arr.join('|')}|"
    end
  end
end