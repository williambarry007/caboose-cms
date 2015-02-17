class Caboose::SocialConfig < ActiveRecord::Base
  self.table_name = "social_configs"
       
  belongs_to :site      
  attr_accessible :id, 
    :site_id              ,
    :facebook_page_id     ,
    :twitter_username     ,
    :instagram_username   ,
    :youtube_url          ,
    :pinterest_url        ,
    :vimeo_url            ,
    :rss_url              ,
    :google_plus_url      ,
    :linkedin_url         , 
    :google_analytics_id  
    
end