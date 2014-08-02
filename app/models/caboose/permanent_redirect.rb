
class Caboose::PermanentRedirect < ActiveRecord::Base
  self.table_name = "permanent_redirects"
  
  attr_accessible :id,
    :site_id,
    :priority,
    :is_regex,
    :old_url,
    :new_url
  
  validates :old_url, :presence => { :message => 'The old URL is required.' }
  validates :new_url, :presence => { :message => 'The new URL is required.' }
  
  def self.match(site_id, uri)
    Caboose::PermanentRedirect.where(:site_id => site_id).reorder(:priority).all.each do |pr|
      if pr.is_regex
        return uri.gsub(/#{pr.old_url}/, pr.new_url) if uri =~ /#{pr.old_url}/ 
      else
        return pr.new_url if uri == pr.old_url
      end
    end
    return false
  end                      
  
end
