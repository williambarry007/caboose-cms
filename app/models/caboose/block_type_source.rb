require 'httparty'

class Caboose::BlockTypeSource < ActiveRecord::Base
  self.table_name = "block_type_sources"
  
  has_many :block_types, :class_name => 'Caboose::BlockType', :order => 'name'    
  attr_accessible :id,
    :name, 
    :url,
    :token,
    :priority,
    :active    

  # Just get the names and descriptions of all block types from the source
  def refresh_names
    resp = nil
    begin                             
      resp = HTTParty.get("#{self.url}/caboose/block-types?token=#{self.token}")
    rescue HTTParty::Error => e
      Caboose.log(e.message)
      return false
    end
    
    block_types = nil
    begin
      block_types = JSON.parse(resp.body)
    rescue
      Caboose.log("Response body isn't valid JSON.")
      return false
    end
    
    block_types.each do |h|      
      next if Caboose::BlockType.where(:name => bt.name).exists?
      Caboose::BlockType.create(:name => h['name'], :description => h['description'])      
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
    
    # Grab all the fields from the hash for the top-level block
    bt.parse_api_hash(h)
    bt.save
    
    # Now add all the children
    h['children'].each do |h2|
      recursive_add(h2, bt.id)
    end
    
    return true
  end
  
  def self.recursive_add(h, parent_id = nil)
    bt = Caboose::BlockType.new(:parent_id => parent_id)
    bt.parse_api_hash(h)
    bt.save
          
    h['children'].each do |h2|
      self.recursive_add(h2, bt.id)
    end
    return bt
  end
end
