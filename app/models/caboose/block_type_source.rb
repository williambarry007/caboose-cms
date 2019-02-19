require 'httparty'

class Caboose::BlockTypeSource < ActiveRecord::Base
  self.table_name = "block_type_sources"
    
  has_many :block_types, -> { order(:name) }, :class_name => 'Caboose::BlockType'
  attr_accessible :id,
    :name, 
    :url,
    :token,
    :priority,
    :active    

  # Just get the names and descriptions of all block types from the source
  def refresh_summaries
    resp = nil
    begin
      resp = HTTParty.get("#{self.url}/caboose/block-types?token=#{self.token}")
    rescue HTTParty::Error => e
      Caboose.log(e.message)
      return false
    end
    
    summaries = nil
    begin
      summaries = JSON.parse(resp.body)
    rescue
      Caboose.log("Response body isn't valid JSON.")
      return false
    end
    
    summaries.each do |h|      
      s = Caboose::BlockTypeSummary.where(:block_type_source_id => self.id, :name => h['name']).first
      s = Caboose::BlockTypeSummary.create(:block_type_source_id => self.id) if s.nil?
      s.parse_api_hash(h)
      s.save
    end
    
    return true
  end
  
  # Get the full block type (including children)
  def refresh(name, force = false)
    bt = Caboose::BlockType.where(:name => name).first
    bt = Caboose::BlockType.create(:name => name) if bt.nil?
    return if bt.downloaded && !force    
    if force
      bt.children.each { |bt2| bt2.destroy }
    end

    # Try to contact the source URL
    resp = nil
    begin                             
      resp = HTTParty.get("#{self.url}/caboose/block-types/#{bt.name}?token=#{self.token}")
    rescue HTTParty::Error => e
      Caboose.log(e.message)
      return false
    end
                
    # Try to parse the response
    h = nil
    begin
      h = JSON.parse(resp.body)
    rescue
      Caboose.log("Response body isn't valid JSON.")
      return false
    end     
    #Caboose.log(h)
    # Update the block type
    bt.parse_api_hash(h)
    
    return true
  end
  
end
