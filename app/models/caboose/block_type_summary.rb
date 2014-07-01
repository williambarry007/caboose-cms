require 'httparty'

class Caboose::BlockTypeSummary < ActiveRecord::Base
  self.table_name = "block_type_summaries"
        
  belongs_to :block_type_source
  attr_accessible :id,
    :block_type_source_id,
    :name,
    :description

  def source
    self.block_type_source
  end
  
  def parse_api_hash(h)    
    self.name        = h['name']
    self.description = h['description']                
  end
  
end
