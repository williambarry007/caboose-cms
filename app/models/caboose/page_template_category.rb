module Caboose
	class PageTemplateCategory < ActiveRecord::Base
	  self.table_name = "page_template_categories"
	  has_many :page_templates, :foreign_key => "category_id"
	  attr_accessible :title, :description, :sort_order, :superadmin_only

	  def self.all_options(blank)
      if blank
        options = [{'value' => '','text' => ''}]
      else
        options = []
      end
      PageTemplateCategory.order(:title).all.each do |s|
        options << { 'value' => s.id, 'text' => s.title }
      end
      return options.to_json
	  end

	end
end