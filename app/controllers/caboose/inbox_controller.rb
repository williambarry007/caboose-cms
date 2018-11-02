module Caboose
  class InboxController < ApplicationController
    layout 'caboose/admin'
    
    # @route GET /admin/inbox
    def admin_index
      where = params[:exclude].blank? ? "(id is not null)" : "(sent_to != '#{params[:exclude]}')"
      @contacts = Caboose::FormSubmission.where(where).where(:site_id => @site.id, :is_spam => false, :is_deleted => false).order('date_submitted desc').all
    end

    # @route GET /admin/inbox/spam
    def admin_spam
      @contacts = Caboose::FormSubmission.where(:site_id => @site.id, :is_spam => true, :is_deleted => false).order('date_submitted desc').all
    end

    # @route GET /admin/inbox/:id
    def admin_show
      @contact = Caboose::FormSubmission.where(:site_id => @site.id, :id => params[:id], :is_deleted => false).first
    end

    # @route GET /admin/inbox/:id/delete
    def admin_delete
      @contact = Caboose::FormSubmission.where(:site_id => @site.id, :id => params[:id]).first
      @contact.is_deleted = true
      @contact.save
      
      redirect_to '/admin/inbox'
    end

    # @route GET /admin/inbox/:id/spam
    def admin_update
      @contact = Caboose::FormSubmission.where(:site_id => @site.id, :id => params[:id]).first
      @contact.is_spam = !@contact.is_spam
      @contact.save
      redirect_to '/admin/inbox/' + params[:id]
    end
            
  end
end