module Caboose
	class PageTemplate < ActiveRecord::Base
	  self.table_name = "page_templates"
	  belongs_to :page
	  belongs_to :category, :class_name => "Caboose::PageTemplateCategory"
	  attr_accessible :page_id, :site_id, :title, :description, :created_at, :updated_at, :category_id, :sort_order
	  has_attached_file :screenshot,
	    :path => ':caboose_prefixpage_templates/:id_screenshot_:style.:extension',
	    :default_url => "https://cabooseit.s3.amazonaws.com/assets/shared/template.png",
	    :styles => {
	      :small  => '300x300>',
	      :medium => '600x600>',
	      :large  => '1000x1000>'
	    }  
	  do_not_validate_attachment_file_type :screenshot
	end
end