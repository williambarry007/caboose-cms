
class Caboose::ApprovalRequest < ActiveRecord::Base
  self.table_name = "approval_reqests"
  belongs_to :page
  belongs_to :user
  belongs_to :reviewer, :class_name => 'User', :foreign_key => 'reviewer_id'
  attr_accessible :page_id, :user_id, :reviewer_id, :date_requested, :date_reviewed, :notes, :reviewer_notes, :status
  
	#const STATUS_APPROVED 	= 'approved';
	#const STATUS_DENIED 	= 'denied';
	#const STATUS_PENDING	= 'pending';
	
end
