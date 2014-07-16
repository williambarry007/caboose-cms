
class Caboose::Asset < ActiveRecord::Base
  self.table_name = "assets"
  belongs_to :page
  attr_accessible :page_id, :uploaded_by_id, :date_uploaded, :name, :filename, :description, :extension

  def sanitize_name(str)
    return str.gsub(' ', '_').downcase 
  end
  
  def assets_with_uri(host_with_port, uri)
    uri[0] = '' if uri.start_with? '/'
    
		page = Page.page_with_uri(host_with_port, File.dirname(uri), false)		
		return false if page.nil?
		
		asset = Asset.where(:page_id => page.id,:filename => File.basename(uri)).first
		return false if asset.nil?
		
		return asset
	end

end
