module Caboose
  class InboxController < ApplicationController
    layout 'caboose/admin'
    
    # @route GET /admin/inbox
    def admin_index
      has_inbox = "Contact".constantize rescue false
      if has_inbox
        where = params[:exclude].blank? ? "(id is not null)" : "(sent_to != '#{params[:exclude]}')"
        @contacts = Contact.where(where).where(:site_id => @site.id, :captcha_valid => true, :deleted => false).order('date_submitted desc').all
      end
    end

    # @route GET /admin/inbox/spam
    def admin_spam
      has_inbox = "Contact".constantize rescue false
      if has_inbox
        @contacts = Contact.where(:site_id => @site.id, :captcha_valid => false, :deleted => false).order('date_submitted desc').all
      end
    end

    # @route GET /admin/inbox/:id
    def admin_show
      has_inbox = "Contact".constantize rescue false
      if has_inbox
        @contact = Contact.where(:site_id => @site.id, :id => params[:id], :deleted => false).first
      end
    end

    # @route GET /admin/inbox/:id/delete
    def admin_delete
      has_inbox = "Contact".constantize rescue false
      if has_inbox
        @contact = Contact.where(:site_id => @site.id, :id => params[:id]).first
        @contact.deleted = true
        @contact.save
        redirect_to '/admin/inbox'
      end
    end

    # @route GET /admin/inbox/:id/spam
    def admin_update
      has_inbox = "Contact".constantize rescue false
      if has_inbox
        @contact = Contact.where(:site_id => @site.id, :id => params[:id]).first
        @contact.captcha_valid = !@contact.captcha_valid
        @contact.save
        redirect_to '/admin/inbox/' + params[:id]
      end
    end
            
  end
end