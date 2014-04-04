require 'httparty'

class Caboose::Timezone < ActiveRecord::Base
  self.table_name = "timezones"
  
  has_many :timezone_offsets, :class_name => 'Caboose::TimezoneOffset'
  attr_accessible :id, :country_code, :name
  
  def self.load_zones(temp_dir = '/tmp', country_codes = ['US'])
    `curl -o #{temp_dir}/timezones.csv.zip http://timezonedb.com/files/timezonedb.csv.zip`
    `unzip #{temp_dir}/timezones.csv.zip -d #{temp_dir}/timezones`

    #Caboose::Timezone.destroy_all
    #Caboose::TimezoneOffset.destroy_all
    
    File.foreach("#{temp_dir}/timezones/zone.csv") do |line|      
      data = CSV.parse_line(line)
      next if !country_codes.include?(data[1])
      next if Caboose::Timezone.where(:id => data[0].to_i).exists?
      Caboose::Timezone.create(
        :id           => data[0].to_i,
        :country_code => data[1], 
        :name         => data[2]
      )
    end
    
    File.foreach("#{temp_dir}/timezones/timezone.csv") do |line|      
      data = CSV.parse_line(line)
      tz_id = data[0].to_i
      next if !Caboose::Timezone.where(:id => tz_id).exists?
      next if Caboose::TimezoneOffset.where(:timezone_id => tz_id, :time_start => data[2].to_i).exists?
      Caboose::TimezoneOffset.create(
        :timezone_id  => data[0].to_i,
        :abbreviation => data[1],
        :time_start   => data[2],
        :gmt_offset   => data[3],
        :dst          => data[4]        
      )
    end
    
    spec = Gem::Specification.find_by_name("caboose-cms")
    gem_root = spec.gem_dir
    
    File.foreach(gem_root + '/lib/sample_files/timezone_abbreviations.csv') do |line|      
      data = CSV.parse_line(line)      
      next if Caboose::TimezoneAbbreviation.where(:abbreviation => data[0]).exists?      
      Caboose::TimezoneAbbreviation.create(        
        :abbreviation => data[0],
        :name         => data[1]                
      )
    end        
    
    `rm -rf #{temp_dir}/timezones`
    `rm -rf #{temp_dir}/timezones.csv.zip`
    
  end
  
  def local(utc_datetime)
    tzo = self.timezone_offsets.where('time_start < ?', utc_datetime.to_i).reorder('time_start desc').first
    return utc_datetime + tzo.gmt_offset.seconds
  end
  
  def string_format(d = DateTime.now.utc)
    tzo = self.timezone_offsets.where('time_start < ?', d.to_i).reorder('time_start desc').first
    total = tzo.gmt_offset.abs
    hours = (total/3600).floor
    x = total - (hours*3600)
    minutes = x > 0 ? (x/60).floor : 0
    seconds = total - (hours*3600) - (minutes*60)
    sign = tzo.gmt_offset >= 0 ? '+' : '-'    
    hours = hours.to_s.rjust(2, '0')    
    return "#{sign}#{hours}#{minutes}"
  end
  
end
