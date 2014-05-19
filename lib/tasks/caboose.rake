require "caboose/version"
require "caboose/migrations"

namespace :caboose do  
  
  desc "Creates/verifies that all database tables and fields are correctly added."
  task :db => :environment do
    Caboose::Schema.create_schema
    Caboose::Schema.load_data    
    if class_exists?('Schema')
      Schema.create_schema
      Schema.load_data
    end
    caboose_correct_sequences
  end

  desc "Creates all caboose tables"
  task :create_schema => :environment do Caboose::Schema.create_schema end

  desc "Loads data into caboose tables"
  task :load_data => :environment do Caboose::Schema.load_data end
      
  desc "Corrects any sequences in tables"
  task :correct_sequences => :environment do
    caboose_correct_sequences    
  end

  desc "Resets the admin password to 'caboose'"
  task :reset_admin_pass => :environment do  
    admin_user = Caboose::User.where(username: 'admin').first
    admin_user.password = Digest::SHA1.hexdigest(Caboose::salt + 'caboose')
    admin_user.save    
  end

  desc "Sync production db to development"
  task :sync_dev_db do
    
    ddb = Rails.application.config.database_configuration['development']
    pdb = Rails.application.config.database_configuration['production']
    
    dump_file = "#{Rails.root}/db/backups/#{pdb['database']}_#{DateTime.now.strftime('%FT%T')}.dump"
    if !File.exists?("#{Rails.root}/db/backups")
      `mkdir -p #{Rails.root}/db/backups`
    end
    
    puts "Capturing production database..."
    `heroku pgbackups:capture --expire`
    
    puts "Downloading production database dump file..."
    `curl -o #{dump_file} \`heroku pgbackups:url\``
    
    puts "Restoring development database from dump file..."
    `pg_restore --verbose --clean --no-acl --no-owner -h #{ddb['host']} -U #{ddb['username']} -d #{ddb['database']} #{dump_file}`
    
  end
  
  desc "Loads and refreshes the timezones from timezonedb.com"
  task :load_timezones => :environment do
    Caboose::Timezone.load_zones('/Users/william/Sites/repconnex/tmp/timezones')
  end
  
  desc "Loads and refreshes the timezones from timezonedb.com"
  task :test_timezones => :environment do
    
    d = DateTime.strptime("04/01/2014 10:00 am -0500", "%m/%d/%Y %I:%M %P %Z")
    puts d    
    d = DateTime.strptime("04/01/2014 10:00 am -0700", "%m/%d/%Y %I:%M %P %Z")
    puts d
  end
  
  desc "Removes duplicate users"
  task :remove_duplicate_users => :environment do    
    while true
      query = ["select email from users group by email having count(email) > ?", 1]    
      rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, query))
      break if rows.nil? || rows.count == 0
      puts "Deleting #{rows.count} emails..."      
      query = ["delete from users where id in (
          select max(A.id) from users A 
          where A.email in (select email from users B group by B.email having count(B.email) > ?)
          group by A.email
        )", 1]
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, query))
    end
  end

  #=============================================================================
  
  def class_exists?(class_name)
    klass = Module.const_get(class_name)
      return klass.is_a?(Class)
    rescue NameError
      return false
  end
  
  # Corrects any sequences in tables
  def caboose_correct_sequences
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

namespace :assets do

  desc "Precompile assets, upload to S3, then remove locally"
  task :purl => :environment do
  
    Rake::Task['assets:precompile'].invoke    
    `mv #{Rails.root.join('public', 'assets', 'manifest.yml')} #{Rails.root.join('public', 'manifest.yml')}`
    `rm -rf #{Rails.root.join('public', 'assets')}`
    `mkdir #{Rails.root.join('public', 'assets')}`     
    `mv #{Rails.root.join('public', 'manifest.yml')} #{Rails.root.join('public', 'assets', 'manifest.yml')}`

  end
  
end
