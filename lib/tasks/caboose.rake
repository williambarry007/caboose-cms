require "caboose/version"

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
  task :sync_dev_db, :app_name, :dump_dir do |t, args|  
    app_name = args[:app_name] ? " --app #{args[:app_name]}" : ''
    dump_dir = args[:dump_dir] ? args[:dump_dir] : "#{Rails.root}/db/backups"
    `mkdir -p #{dump_dir}` if !File.exists?(dump_dir)
    
    # Get the db conf
    ddb = Rails.application.config.database_configuration['development']
    pdb = Rails.application.config.database_configuration['production']            
    dump_file = "#{dump_dir}/#{pdb['database']}_#{DateTime.now.strftime('%FT%T')}.dump"    
        
    puts "Capturing production database..."
    `heroku pgbackups:capture --expire#{app_name}`
    
    puts "Downloading production database dump file..."
    `curl -o #{dump_file} \`heroku pgbackups:url#{app_name}\``
    
    puts "Restoring development database from dump file..."
    `pg_restore --verbose --clean --no-acl --no-owner -h #{ddb['host']} -U #{ddb['username']} -d #{ddb['database']} #{dump_file}`
  end
                 
  desc "Clears sessions older than the length specified in the caboose config from the sessions table"
  task :clear_old_sessions => :environment do
    ActiveRecord::SessionStore::Session.delete_all(["updated_at < ?", Caboose::session_length.hours.ago])        
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
  
    # Copy any site assets into the host app assets directory first
    puts "Copying site assets into host assets..."
    Caboose::Site.all.each do |site|
      site_js     = Rails.root.join('sites', site.name, 'js')    
      site_css    = Rails.root.join('sites', site.name, 'css')   
      site_images = Rails.root.join('sites', site.name, 'images')
      site_fonts  = Rails.root.join('sites', site.name, 'fonts') 
          
      host_js     = Rails.root.join('app', 'assets', 'javascripts' , site.name)
      host_css    = Rails.root.join('app', 'assets', 'stylesheets' , site.name)
      host_images = Rails.root.join('app', 'assets', 'images'      , site.name)
      host_fonts  = Rails.root.join('app', 'assets', 'fonts'       , site.name)
      
      `mkdir -p #{host_js     }` if File.directory?(site_js) 
      `mkdir -p #{host_css    }` if File.directory?(site_css) 
      `mkdir -p #{host_images }` if File.directory?(site_images) 
      `mkdir -p #{host_fonts  }` if File.directory?(site_fonts)
                             
      `cp -R #{site_js     } #{host_js     }` if File.directory?(site_js) 
      `cp -R #{site_css    } #{host_css    }` if File.directory?(site_css) 
      `cp -R #{site_images } #{host_images }` if File.directory?(site_images) 
      `cp -R #{site_fonts  } #{host_fonts  }` if File.directory?(site_fonts) 
    end
    
    puts "Running precompile..."
    Rake::Task['assets:precompile'].invoke

    puts "Removing assets from public/assets, but leaving manifest file..."    
    `mv #{Rails.root.join('public', 'assets', 'manifest.yml')} #{Rails.root.join('public', 'manifest.yml')}`
    `rm -rf #{Rails.root.join('public', 'assets')}`
    `mkdir #{Rails.root.join('public', 'assets')}`     
    `mv #{Rails.root.join('public', 'manifest.yml')} #{Rails.root.join('public', 'assets', 'manifest.yml')}`
    
    # Clean up
    puts "Removing site assets from host assets..."
    Caboose::Site.all.each do |site|      
      host_js     = Rails.root.join('app', 'assets', 'javascripts' , site.name)
      host_css    = Rails.root.join('app', 'assets', 'stylesheets' , site.name)
      host_images = Rails.root.join('app', 'assets', 'images'      , site.name)
      host_fonts  = Rails.root.join('app', 'assets', 'fonts'       , site.name)
                             
      `rm -rf #{host_js     }`
      `rm -rf #{host_css    }`
      `rm -rf #{host_images }` 
      `rm -rf #{host_fonts  }`
    end

  end
  
  desc "Fix variant sort order"
  task :set_variant_sort_order => :environment do
    Caboose::Product.all.each do |p|
      puts "Setting sort order for product #{p.id}..."
      i = 1
      Caboose::Variant.where(:product_id => p.id).reorder(:id).all.each do |v|
        v.update_attribute('sort_order', i)
        i = i + 1
      end
    end
  end
  
end
