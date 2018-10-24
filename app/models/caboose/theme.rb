class Caboose::Theme < ActiveRecord::Base

  self.table_name = "themes"

  has_many :theme_file_memberships
  has_many :theme_files, :through => :theme_file_memberships    

  has_attached_file :default_banner_image,      
    :path => 'banner_images/:id_:style.:extension',      
    :default_url => 'https://res.cloudinary.com/caboose/image/upload/c_scale,f_auto,q_auto:good,w_1800/v1539265856/default_banner.jpg',
    :s3_protocol => :https,
    :styles      => {
      huge:   '1800x1800>'
    }
  do_not_validate_attachment_file_type :default_banner_image

	attr_accessible :id,
    :color_main,
    :color_alt,
		:color_dark,
		:color_light,
		:max_width,
		:body_bg_color,
		:font_size,
		:header_height,
		:header_bg_color,
		:header_font_color,
		:dropdown_color,
		:mobile_menu_bg_color,
		:mobile_menu_font_color,
		:mobile_menu_border_color,
		:mobile_menu_icon_color,
		:mobile_menu_icon_top,
		:footer_height,
		:footer_bg_color,
		:footer_font_color,
		:btn_border_radius,
		:btn_border_width,
		:btn_border_color,
		:btn_font_color,
		:btn_font_size,
		:btn_font_weight,
		:btn_font_case,
		:btn_border_side,
		:input_border_radius,
		:input_bg_color,
		:input_border_color,
		:input_border_width,
		:input_font_color,
		:input_font_size,
		:input_padding,

		:body_line_height,
		:body_font_color,
		:button_padding,
		:button_line_height,
		:footer_padding,
		:footer_font_size,
		:header_font_size,
		:note_padding,
		:header_nav_spacing,
		:logo_width,
		:logo_height,
		:logo_top_padding,
		:heading_line_height,
		:mobile_menu_nav_padding,
		:mobile_menu_font_size,
		:banner_padding,
		:banner_overlay_color,
		:banner_overlay_opacity,
		:default_header_style,
		:default_header_position,
		:sidebar_width,
		:sidebar_bg_color,

		:banner_font_size,
		:footer_hover_color,
		:actual_footer_height,
		:actual_banner_height,
		:dropdown_nav_padding,

    :digest,
    :custom_sass,
    :cl_banner_version

  def compile(for_site_id = 0)
  	theme = self
  	theme_name = 'default'
  	path = Rails.root.join('themes', "#{theme_name}.scss.erb")
  	body = ERB.new(File.read(File.join(path))).result(theme.get_binding(for_site_id))
  	tmp_themes_path = File.join(Rails.root, 'tmp', 'themes')
  	tmp_asset_name = "theme_#{self.id}_site_#{for_site_id}"
  	FileUtils.mkdir_p(tmp_themes_path) unless File.directory?(tmp_themes_path)
  	File.open(File.join(tmp_themes_path, "#{tmp_asset_name}.scss"), 'w') { |f| f.write(body) }
		begin
	    env = if Rails.application.assets.is_a?(Sprockets::Index)
	      Rails.application.assets.instance_variable_get('@environment')
	    else
	      Rails.application.assets
	    end
	    asset = env.find_asset(tmp_asset_name)
	    compressed_body = ::Sass::Engine.new(asset.body, {
	      :syntax => :scss,
	      :cache => false,
	      :read_cache => false,
	      :style => :compressed
	    }).render
	    str = StringIO.new(compressed_body)
	    if Rails.env.production?
	      config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]
		    AWS.config(:access_key_id => config['access_key_id'], :secret_access_key => config['secret_access_key'])
		    bucket =  AWS::S3.new.buckets[config['bucket']]                         
		    bucket.objects[theme.asset_path(asset.digest, for_site_id)].write(str, :acl => 'public-read', :content_type => 'text/css')
	    else
	    	theme_path = File.join(Rails.root, 'public', 'assets', 'themes')
				FileUtils.mkdir_p(theme_path) unless File.directory?(theme_path)
	      File.open(File.join(Rails.root, 'public', theme.asset_path(asset.digest, for_site_id)), 'w') { |f| f.write(compressed_body) }
	    end
	    self.update_digest(asset.digest)
		rescue Sass::SyntaxError => error
			if Rails.env.development?
				raise error
			end
			theme.revert
		end
  end

  def revert
 		Caboose.log("reverting theme")
  end

  def get_binding(site_id)
  	binding
  end

  def delete_asset
  	Caboose.log("deleting asset")
  end

  def asset_path(digest = self.digest, site_id = 0)
		"assets/themes/#{asset_name(digest, site_id)}.css"
	end

	def asset_name(digest = self.digest, site_id = 0)
		"theme_#{self.id}_site_#{site_id}-#{digest}"
	end

	def asset_url(site_id = 0)
		if Rails.env.production?
			return "https://#{ActionController::Base.asset_host}/#{asset_path(self.digest,site_id)}"
		else
			path = File.join(Rails.root, 'public', "#{asset_path(self.digest,site_id)}")
			if File.file?(path)
				return "#{ActionController::Base.asset_host}/#{asset_path(self.digest,site_id)}"
			else
				return "https://#{Caboose::cdn_domain}/#{asset_path(self.digest,site_id)}"
			end
		end
	end

	def js_url
		# TODO - figure out how to do this 
		"https://cabooseit.s3.amazonaws.com/assets/natureseyenri/js/application.js"
	end

	def update_digest(digest)
		self.update_column('digest', digest)
	end

	def update_cloudinary_banner
		if Caboose::use_cloudinary
			url = self.default_banner_image.url(:huge)
			url = "https:#{url}" if !url.include?('https')
			if !url.include?('res.cloudinary')
	      result = Cloudinary::Uploader.upload(url , :public_id => "banner_images/#{self.id}_huge", :overwrite => true)
	      self.cl_banner_version = result['version'] if result && result['version']
	      self.save
	    end
    end
	end
    
end