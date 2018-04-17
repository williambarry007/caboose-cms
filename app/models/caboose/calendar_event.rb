module Caboose
  class CalendarEvent < ActiveRecord::Base    
    self.table_name = "calendar_events"
    
    belongs_to :calendar
    belongs_to :calendar_event_group
    attr_accessible :id        ,
      :calendar_id             ,
      :calendar_event_group_id , 
      :name                    ,
      :description             ,
      :location                ,
      :begin_date              ,
      :end_date                ,
      :all_day                 ,
      :repeats                 ,
      :published               ,
      :url                     ,
      :url_label 


    has_attached_file :image, 
      :path => ':caboose_prefixevents/:id_:style.:extension',
      :default_url => 'http://placehold.it/300x300',
      :styles => {
        :thumb => '150x150>',
        :large => '800x800>',
        :huge => '1600x1600>'
      }
    do_not_validate_attachment_file_type :image

    def self.events_for_day(calendar_id, d)
      q = ["calendar_id = ? 
        and cast(begin_date as date) <= ?
        and cast(end_date   as date) >= ?",
        calendar_id, d.to_date, d.to_date]
      self.where(q).reorder(:begin_date).all
    end
    
    def duplicate(d)
      btime = self.begin_date.to_s[10..-1]
      etime = self.end_date.to_s[10..-1]
      bdate = DateTime.parse(d.to_s + btime)
      edate = DateTime.parse(d.to_s + btime) + (self.end_date - self.begin_date).seconds
      e = CalendarEvent.create(        
        :calendar_id             => self.calendar_id,
        :calendar_event_group_id => self.calendar_event_group_id,
        :name                    => self.name,
        :description             => self.description,
        :location                => self.location,
        :begin_date              => bdate,
        :end_date                => edate,
        :all_day                 => self.all_day,
        :repeats                 => self.repeats,
        :published               => self.published,
        :url                     => self.url
      )
      return e
    end

  end
end
