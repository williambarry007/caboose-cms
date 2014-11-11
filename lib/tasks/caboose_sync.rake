
namespace :caboose do

  desc "Create YAML test fixtures from data in the development database."
  task :fixtures => :environment do
    sql  = "SELECT * FROM %s"
    skip_tables = ["schema_migrations"]
    ActiveRecord::Base.establish_connection(Rails.env)
    (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
      
      count = ActiveRecord::Base.connection.select_value("select count(*) from #{table_name}")
      count = count.to_i
      data = ''
      if count > 0
        i = 1
        pad_count = Math.log(count, 10).ceil
        rows = ActiveRecord::Base.connection.select_all(sql % table_name)
        h = {}
        rows.each do |row| 
          h["#{table_name}_#{i.to_s.rjust(pad_count, '0')}"] = row
          i = i + 1
        end
        data = h.to_yaml.gsub(/<%([^%])/, '<%%\1')

        #data = rowsdata.inject({}) { |hash, record|
        #  hash["#{table_name}_#{i.succ!}"] = record
        #  hash
        #}.to_yaml.gsub(/<%([^%])/, '<%%\1')
      end
          
      File.open("#{Rails.root}/test/fixtures/#{table_name}.yml", 'w') do |file|          
        file.write data            
      end      
    end

    ## Now escape any erb code in there
    #Dir["#{Rails.root}/test/fixtures/*.yml"].each do |fname|      
    #  file = File.open(fname, "rb")      
    #  str = file.read
    #  str2 = str.gsub(/<%([^%])/, '<%%\1')
    #  if str2 != str
    #    File.open(fname, 'w') { |file| file.write(str2) }
    #  end                  
    #end    
  end  

  namespace :sync do  
      
    desc "Sync production database to development database"
    task :production_to_development do |t, args|
      sync_db('production', 'development')      
    end
    
    desc "Sync development database to test database"
    task :development_to_test do |t, args|
      sync_db('development', 'test')      
    end
    
    desc "Sync production database to development database"
    task :p2d do |t, args|
      sync_db('production', 'development')      
    end
    
    desc "Sync development database to test database"
    task :d2t do |t, args|
      sync_db('development', 'test')      
    end
  
    def sync_db(from_db, to_db)
      # Get the app name
      app_name = `grep "git@heroku.com" "#{Rails.root}/.git/config"`      
      app_name = app_name.strip.gsub(/^url = git@heroku.com\:(.*?).git$/, '\1')      
                
      # Get the db confs    
      from_conf = Rails.application.config.database_configuration[from_db]
      to_conf   = Rails.application.config.database_configuration[to_db]
      
      dump_dir = "#{Rails.root}/db/backups"
      `mkdir -p #{dump_dir}` if !File.exists?(dump_dir)    
      dump_file = "#{dump_dir}/#{app_name}_#{from_db}_#{DateTime.now.strftime('%Y%m%d%H%M')}.dump"

      if from_db == 'production'
        
        puts "Capturing production database..."
        `heroku pgbackups:capture --expire --app #{app_name}`
        
        puts "Downloading production database dump file..."
        `curl -o #{dump_file} \`heroku pgbackups:url --app #{app_name}\``
        
      elsif from_db == 'development'
        
        puts "Dumping development database..."
        host = from_conf['host'] ? from_conf['host'] : 'localhost'
        `pg_dump -Fc --no-acl --no-owner -h #{host} -U #{from_conf['username']} #{from_conf['database']} > #{dump_file}`      
        
      end
      
      if to_db == 'development' || to_db == 'test'
      
        puts "Restoring database to #{to_db} from dump file..."
        host = to_conf['host'] ? to_conf['host'] : 'localhost'        
        `pg_restore --verbose --clean --no-acl --no-owner -h #{host} -U #{to_conf['username']} -d #{to_conf['database']} #{dump_file}`
        
      elsif to_db == 'production'
        
        puts "Syncing to production database is not supported."
        
      end
    end
           
  end
end
