module Caboose
  class AssetsController < Caboose::ApplicationController
    layout 'caboose/admin'
            
    # @route GET /admin/assets
    def admin_index
      return if !user_is_allowed('assets', 'edit')
      config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]          
      bucket = config['bucket']
      @assets_path = "http://#{bucket}.s3.amazonaws.com/assets"
    end
    
    # @route GET /admin/assets/manifest
    def admin_manifest
      return if !user_is_allowed('assets', 'edit')
      
      config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]          
      bucket = config['bucket']
      resp = HTTParty.get("http://#{bucket}.s3.amazonaws.com/assets/manifest.yml")      
      str = resp.body             
      manifest = self.parse_manifest(str, true)
      
      render :json => manifest            
    end
    
    def parse_manifest(str, exclude_images = true)
      lines = str.split("\n")
      h = {}
      lines.each_with_index do |line, i|
        next if i == 0
        path = line.split(": ").first.split('/')
        
        if exclude_images
          ext = line.split('.')
          next if ext.count > 0 && ['png','jpg','gif','ico'].include?(ext.last.downcase)
        end
        self.verify_path_exists(path, h)
      end
      return h
    end
    
    def verify_path_exists(path, h, i = 0)
      return if i >= path.count
      h[path[i]] = i == (path.count - 1) ? true : {} if h[path[i]].nil?
      self.verify_path_exists(path, h[path[i]], i+1)
    end
          
    #
    # benttree/images/icons/apple-touch-icon.png
    #
    # {
    #   :bentree => {
    #     :images => {
    #       :icons => {
    #         'apple-touch-icon.png' => true
    #       }
    #     }
    #   }
    # }
    #

  end
end
