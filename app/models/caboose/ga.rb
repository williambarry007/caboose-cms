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

      HTTParty.get('https://www.google-analytics.com', { 'query' => params })      
    end
    
  end  
end
