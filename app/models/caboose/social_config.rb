class Caboose::SocialConfig < ActiveRecord::Base
  self.table_name = "social_configs"
       
  belongs_to :site, :class_name => "Caboose::Site"

  attr_accessible :id, 
    :site_id              ,
    :facebook_page_id     ,
    :twitter_username     ,
    :instagram_username   ,
    :instagram_user_id    ,
    :instagram_access_token,
    :youtube_url          ,
    :pinterest_url        ,
    :vimeo_url            ,
    :rss_url              ,
    :google_plus_url      ,
    :linkedin_url         , 
    :google_analytics_id

    has_attached_file :share_image,      
      :path => ':share_images/:id_:style.:extension',      
      :default_url => 'http://placehold.it/800x500',
      :s3_protocol => :https,
      :styles      => {
        large:   '1200x1200>'
      }
    do_not_validate_attachment_file_type :share_image
    
end