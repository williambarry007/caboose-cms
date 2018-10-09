class Caboose::Theme < ActiveRecord::Base

  self.table_name = "themes"

  belongs_to :site, :class_name => "Caboose::Site"

  after_save :compile

	attr_accessible :id,
		:site_id,
    :color_main,
    :color_alt,
    :digest

  def self.compile(theme_id)
  	theme = Caboose::Theme.find(theme_id)
  	path = Rails.root.join(Caboose::site_assets_path, theme.site.name, 'css', 'theme.scss.erb')
  	Caboose.log("path: #{path}") 
  	body = ERB.new(File.read(File.join(path))).result(theme.get_binding)
  	Caboose.log("body:")
  	Caboose.log(body)
  	tmp_themes_path = File.join(Rails.root, 'tmp', 'themes')
  	tmp_asset_name = "theme_#{theme.id}"
  	FileUtils.mkdir_p(tmp_themes_path) unless File.directory?(tmp_themes_path)
  	File.open(File.join(tmp_themes_path, "#{tmp_asset_name}.scss"), 'w') { |f| f.write(body) }
#  	begin
	    env = if Rails.application.assets.is_a?(Sprockets::Index)
	      Rails.application.assets.instance_variable_get('@environment')
	    else
	      Rails.application.assets
	    end
	    Caboose.log("tmp_asset_name: #{tmp_asset_name}")
	    asset = env.find_asset(tmp_asset_name)
	    Caboose.log(asset)
	    compressed_body = ::Sass::Engine.new(asset.body, {
	      :syntax => :scss,
	      :cache => false,
	      :read_cache => false,
	      :style => :compressed
	    }).render
	    str = StringIO.new(compressed_body)
	    Caboose.log( compressed_body.to_s )
	    theme.delete_asset
	    if Rails.env.production?
	      config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]
		    AWS.config(:access_key_id => config['access_key_id'], :secret_access_key => config['secret_access_key'])
		    bucket =  AWS::S3.new.buckets[config['bucket']]                         
		    bucket.objects[theme.asset_path(asset.digest)].write(str, :acl => 'public-read', :content_type => 'text/css')
	    else
	      File.open(File.join(Rails.root, 'public', theme.asset_path(asset.digest)), 'w') { |f| f.write(compressed_body) }
	    end
	    update_digest(theme.id, asset.digest)
	#  rescue Sass::SyntaxError => error
	##    theme.revert
	#  end
  end

  def revert
  	# revert to previous theme
  end

  def get_binding
  	binding
  end

  def delete_asset
  	return unless digest?
  	# delete old asset
  end

  def asset_path(digest)
		"assets/themes/#{asset_name(digest)}.css"
	end

	def asset_name(digest = self.digest)
		"#{self.site.id}-#{digest}"
	end

	def asset_url
		"#{ActionController::Base.asset_host}/#{asset_path}"
	end

	def self.update_digest(theme_id, digest)
		Caboose::Theme.find(theme_id).update_column('digest',digest)
	end

  private

  def compile
  	self.class.compile(self.id)
  end
    
end