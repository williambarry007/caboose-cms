
module Caboose
  class ModelBinder
    
    # Converts a 12-hour time string to a 24-hour time string.  
    # Example: 3:37 pm -> 15:37 
    def self.military_time(str)
      return false if str.nil? || str.length == 0
      arr = str.split(' ')
      return str if arr.length == 1
      hm = arr[0]
      ampm = arr[1].downcase
      return hm if ampm == 'am'
      arr2 = hm.split(':')
      arr2[0] = (arr2[0].to_i + 12).to_s
      return arr2.join(':')
    end
    
    # Given a local date and time string (iso8601 format) and the local timezone, 
    # return a datetime object in the UTC zone.
    def self.local_datetime_to_utc(str, zone)
                      
      return false if str.nil? || zone.nil?
      
      # Split into date and time
      arr = str.split('T')      
      arr = str.split(' ') if arr.count == 1      
      return false if arr.count == 1
      
      # Split up the date into its components
      date_string = arr.shift
      d = date_string.split('-')
      d = date_string.split('/') if d.count == 1      
      return false if d.count != 3
      d = [d[2], d[0], d[1]] if date_string.include?('/')
      
      # Split up the time into its components
      time_string = arr.join(' ')
      time_string = ModelBinder.military_time(time_string)
      t = time_string.split(':')
      return false if t.count != 2 && t.count != 3
      
      # Convert timezones
      old_timezone = Time.zone
      Time.zone = zone                    
      local_d = Time.zone.local(d[0].to_i, d[1].to_i, d[2].to_i, t[0].to_i, t[1].to_i, (t.count > 2 ? t[2].to_i : 0)).to_datetime.utc
      Time.zone = old_timezone
      
      return local_d
    end
    
    def self.update_date(d, value, timezone)                      
      t = d ? d.in_time_zone(timezone).strftime('%H:%M') : '10:00'            
      return ModelBinder.local_datetime_to_utc("#{value} #{t}", timezone)
    end
    
    def self.update_time(d, value, timezone)                        
      d2 = d ? d.in_time_zone(timezone).strftime('%Y-%m-%d') : DateTime.now.strftime('%Y-%m-%d')
      return ModelBinder.local_datetime_to_utc("#{d2} #{value}", timezone)
    end
        
  end
end
