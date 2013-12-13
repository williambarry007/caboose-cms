
namespace :caboose do    
  desc "Corrects any sequences in tables"
  task :correct_sequences => :environment do
    
    c = ActiveRecord::Base.connection
    c.tables.each do |tbl|      
      next if !c.column_exists? tbl, :id
      
      rows = c.execute("select max(id) from #{tbl}")      
      max = rows[0]['max']
      max = max.to_i if !max.nil?
      
      rows = c.execute("select nextval('#{tbl}_id_seq')")
      nextval = rows[0]['nextval']
      nextval = nextval.to_i if !nextval.nil?
      
      next if max.nil? || nextval.nil?
      next if nextval >= max
      
      # If nextval is lower than the max id, then fix it.
      puts "Correcting sequence for #{tbl}..."
      c.execute("select setval('#{tbl}_id_seq', (select max(id) from #{tbl}))")
      
    end
  end
end
