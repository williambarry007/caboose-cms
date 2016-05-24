module Caboose
  class FontsController < ApplicationController
    layout 'caboose/admin'
    
    # @route GET /admin/fonts
    def admin_index
      @hf = Font.where(:site_id => @site.id, :name => "heading-font").last
      if !@hf then @hf = Font.create(:site_id => @site.id, :name => "heading-font", :family => "Open Sans", :variant => "600", :url => "http://fonts.gstatic.com/s/opensans/v13/MTP_ySUJH_bn48VBG8sNSi3USBnSvpkopQaUR-2r7iU.ttf") end
      @bf = Font.where(:site_id => @site.id, :name => "body-font").last
      if !@bf then @bf = Font.create(:site_id => @site.id, :name => "body-font", :family => "Open Sans", :variant => "regular", :url => "http://fonts.gstatic.com/s/opensans/v13/IgZJs4-7SA1XX_edsoXWog.ttf") end
      @bfb = Font.where(:site_id => @site.id, :name => "body-font-bold").last
      if !@bfb then @bfb = Font.create(:site_id => @site.id, :name => "body-font-bold", :family => "Open Sans", :variant => "600", :url => "http://fonts.gstatic.com/s/opensans/v13/MTP_ySUJH_bn48VBG8sNSi3USBnSvpkopQaUR-2r7iU.ttf") end
      @bfi = Font.where(:site_id => @site.id, :name => "body-font-italic").last
      if !@bfi then @bfi = Font.create(:site_id => @site.id, :name => "body-font-italic", :family => "Open Sans", :variant => "italic", :url => "http://fonts.gstatic.com/s/opensans/v13/O4NhV7_qs9r9seTo7fnsVKCWcynf_cDxXwCLxiixG1c.ttf") end
      @bfbi = Font.where(:site_id => @site.id, :name => "body-font-bold-italic").last
      if !@bfbi then @bfbi = Font.create(:site_id => @site.id, :name => "body-font-bold-italic", :family => "Open Sans", :variant => "600italic", :url => "http://fonts.gstatic.com/s/opensans/v13/PRmiXeptR36kaC0GEAetxpZ7xm-Bj30Bj2KNdXDzSZg.ttf") end
      @btn = Font.where(:site_id => @site.id, :name => "button-font").last
      if !@btn then @btn = Font.create(:site_id => @site.id, :name => "button-font", :family => "Open Sans", :variant => "regular", :url => "http://fonts.gstatic.com/s/opensans/v13/IgZJs4-7SA1XX_edsoXWog.ttf") end
    end

    # @route PUT /admin/fonts
    def admin_update
      resp = StdClass.new
      family = params[:family]
      name = params[:name]
      url = params[:url]
      variant = params[:variant]

      if !family.blank? && !name.blank? && !url.blank? && !variant.blank?
        font = Font.where(:site_id => @site.id, :name => name).last
        if font
          font.family = family
          font.url = url
          font.variant = variant
          font.save
          resp.success = "Font saved!"
        else
          resp.error = "Font doesn't exist yet"
        end
      else
        resp.error = "Error saving font"
      end
      render :json => resp

    end
            
  end
end