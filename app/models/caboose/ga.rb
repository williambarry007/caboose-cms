require 'httparty'

module Caboose
  class GA # Google Analytics

    def self.event(site_id, category, action, label = nil, value = nil)
      
      site = Site.where(:id => site_id).first
      return if site.nil?
      sc = site.social_config
      ga_id = sc.google_analytics_id
      return if ga_id.nil? || ga_id.strip.length == 0 
    
      params = {
        'v'   => 1,
        'tid' => ga_id,
        'cid' => site.id,
        't'   => "event",      
        'ec'  => category,
        'ea'  => action
      }
      params['el'] = label if label
      params['ev'] = value if value    

      HTTParty.post('http://www.google-analytics.com/collect', :body => params)      
    end
    
  end  
end
