
class Caboose::Utilities::Schema
   
  # Tables (in order) that were renamed in the development of the gem.
  def self.renamed_tables
    return nil
  end
  
  # Columns (in order) that were removed in the development of the gem.
  def self.removed_columns
    return nil
  end
  
  # Any column indexes that need to exist in the database
  def self.indexes
    return nil      
  end      
  
  # The schema of the database
  # { Model => [[name, data_type, options]] }
  def self.schema
    raise NotImplementedError.new("You must implement this")
  end
  
  # Loads initial data into the database
  def self.load_data
  end
    
  #===========================================================================
  # Methods that extended classes will use
  #===========================================================================
  
  # Verifies (non-destructively) that the given schema exists in the database.
  def self.create_schema
    return if self.schema.nil?
    
    rename_tables
    remove_columns
    
    c = ActiveRecord::Base.connection
    self.schema.each do |model, columns|
      tbl = model.table_name
      #puts "Creating table #{tbl}..."
      c.create_table tbl if !c.table_exists?(tbl)
      columns.each do |col|
        #puts "Creating column #{tbl}.#{col[0]}..."                 
        
        # Skip if the column exists with the proper data type
        next if c.column_exists?(tbl, col[0], col[1])
        
        # If the column doesn't exists, add it
        if !c.column_exists?(tbl, col[0])
          if col.count > 2                      
            c.add_column tbl, col[0], col[1], col[2]
          else          
            c.add_column tbl, col[0], col[1] 
          end
          
        # Column exists, but not with the correct data type, try to change it
        else          
          
          c.execute("alter table #{tbl} alter column #{col[0]} type #{col[1]} using cast(#{col[0]} as #{col[1]})")
          
          # Add a temp column
          #c.remove_column tbl, "#{col[0]}_temp" if c.column_exists?(tbl, "#{col[0]}_temp")
          #if col.count > 2
          #  c.add_column tbl, "#{col[0]}_temp", col[1], col[2]
          #else
          #  c.add_column tbl, "#{col[0]}_temp", col[1]
          #end
          
          # Copy the old column and cast with correct data type to the new column
          #model.all.each do |m|            
          #  m["#{col[0]}_temp"] = case col[1]
          #    when :integer  then m[col[0]].to_i
          #    when :string   then m[col[0]].to_s
          #    when :text     then m[col[0]].to_s
          #    when :numeric  then m[col[0]].to_f
          #    when :datetime then DateTime.parse(m[col[0]])
          #    when :boolean  then m[col[0]].to_i == 1
          #    else nil
          #    end
          #  m.save
          #end
          
          # Remove the old column and rename the new one
          #c.remove_column tbl, col[0]
          #c.rename_column tbl, "#{col[0]}_temp", col[0]          
    
        end
      end
    end    
    create_indexes
    
    self.schema.each do |model, columns|
      model.reset_column_information
    end
  end
  
  # Verifies (non-destructively) that the given indexes exist in the database.
  def self.create_indexes
    return if self.indexes.nil?
    c = ActiveRecord::Base.connection      
    self.indexes.each do |table, indexes|
      indexes.each do |index|
        c.add_index table, index if !c.index_exists?(table, index)
      end
    end
  end
  
  # Renames a set of tables 
  def self.rename_tables
    return if self.renamed_tables.nil?
    c = ActiveRecord::Base.connection
    self.renamed_tables.each do |old_name, new_name|
      c.rename_table old_name, new_name if c.table_exists?(old_name)
    end
  end
  
  # Removes a set of tables 
  def self.remove_columns
    return if self.removed_columns.nil?
    c = ActiveRecord::Base.connection
    self.removed_columns.each do |model, columns|
      columns.each do |col|
        c.remove_column model.table_name, col if c.column_exists?(model.table_name, col)
      end
    end
  end
  
end
