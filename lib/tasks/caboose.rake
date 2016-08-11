require "caboose/version"
require 'aws-sdk'

namespace :caboose do
  
  desc "Refresh invoice transactions"
  task :refresh_invoice_transactions => :environment do
    inv = Caboose::Invoice.where(:status => 'pending').reorder("id desc").first
    inv.refresh_transactions        
  end
  
  desc "Change orders to invoices in custom functions"
  task :order_to_invoices => :environment do
    Caboose::StoreConfig.all.each do |sc|      
      sc.custom_packages_function = order_to_invoices_in_string(sc.custom_packages_function ) if sc.custom_packages_function && sc.custom_packages_function.strip.length > 0       
      sc.custom_shipping_function = order_to_invoices_in_string(sc.custom_shipping_function ) if sc.custom_shipping_function && sc.custom_shipping_function.strip.length > 0
      sc.custom_tax_function      = order_to_invoices_in_string(sc.custom_tax_function      ) if sc.custom_tax_function      && sc.custom_tax_function.strip.length      > 0
      #sc.starting_invoice_number  = sc.starting_order_number if sc.starting_order_number
      sc.save
    end    
  end
  
  def order_to_invoices_in_string(str)
    str = str.gsub('Order', 'Invoice')
    str = str.gsub('order', 'invoice')
    str = str.gsub('Binvoice', 'Border')
    str = str.gsub('binvoice', 'border')
    str = str.gsub('reinvoice', 'reorder')
    return str
  end
  
  desc "Check ruby syntax in all ruby files"
  task :check_syntax => :environment do    
    puts "Checking syntax in all ruby files...\n\n"
    
    str = `find #{Rails.root} -name "*.rb"`
    files = str ? str.strip.split("\n") : []
    
    errors = {}
    files.each do |file|
      str = `ruby -c #{file}`      
      next if str.nil? || str.strip == 'Syntax OK'
      errors[file] = str
    end
    
    if errors.count == 0      
      puts "                                           \n"
      puts "             █████                         \n"
      puts "            ███████                        \n"
      puts "           ███   ██                        \n"
      puts "           ██    ██                        \n"
      puts "          ███    ███                       \n"
      puts "          ███    ███                       \n"
      puts "           ██     ███                      \n"
      puts "           ███     ███                     \n"
      puts "            ███     ████                   \n"
      puts "             ██      ████                  \n"
      puts "             ███       ███                 \n"
      puts "              ███       ███                \n"
      puts "              ███        ███               \n"
      puts "               ██          ███             \n"
      puts "           ███ ███          ██             \n"
      puts "      ████████████           ███           \n"
      puts "    ████████                  ███          \n"
      puts "   ███                         █████████   \n"
      puts "  ███    █████████                  █████  \n"
      puts "  ██   ███████ ████                   ███  \n"
      puts "  ██    ███       ███                  ██  \n"
      puts "  ███           █████                  ██  \n"
      puts "   ███       ████████                  ██  \n"
      puts "    ████████████   ████                ██  \n"
      puts "   ███ ██████       ████               ██  \n"
      puts "   ███           ██████                ██  \n"
      puts "    ████ ████ ██████████               ██  \n"
      puts "     ████████████     ███             ███  \n"
      puts "      ██           ███████       ███████   \n"
      puts "      ████      ████████        ████████   \n"
      puts "       ████████████   ███     ███          \n"
      puts "          ███ █ █      ███   ███           \n"
      puts "          ███      █████  █████            \n"
      puts "           ██████████████████              \n"
      puts "            ██████████████                 \n"
      puts "\n"
      puts "Syntax is OK in all files.\n"
      puts "\n"
    else
      puts "\n"
      puts "--------------------------------------------------------------------\n";
      puts "IMPORTANT\n"
      puts "Errors detected. Please correct before pushing to production."      
      puts "--------------------------------------------------------------------\n";
    end     
  end
  
  desc "Update super admin password"
  task :update_superadmin_password => :environment do
    sa = Caboose::User.where(:username => 'superadmin').first        
    print "Enter a new password: "
    sa.password = STDIN.noecho(&:gets).chomp
    puts "\n\nThe password has been updated.\n\n"    
    sa.password = Digest::SHA1.hexdigest(Caboose::salt + sa.password)
    sa.save    
  end
          
  desc "Show all comment routes in controllers"  
  task :routes, [:arg1] => :environment do |t, args|    
    puts Caboose::CommentRoutes.controller_routes(args ? args.first : nil)        
  end
  
  desc "Compare routes in controllers with routes in the routes file"
  task :compare_routes, [:arg1, :arg2] => :environment do |t, args|
    # controller, route_file
    Caboose::CommentRoutes.compare_routes(args[:arg1], args[:arg2])
  end
  
  desc "Calculate invoice profits"  
  task :calculate_invoice_profits => :environment do        
    Caboose::Invoice.where("status = ? or status = ? or status = ?", Caboose::Invoice::STATUS_PENDING, Caboose::Invoice::STATUS_READY_TO_SHIP, Caboose::Invoice::STATUS_SHIPPED).reinvoice(:id).all.each do |invoice|
      invoice.update_column(:cost   , invoice.calculate_cost   )
      invoice.update_column(:profit , invoice.calculate_profit )
    end                    
  end
  
  desc "Verify ELO and ELI roles exist for all sites"
  task :init_site_users_and_roles => :environment do
    Caboose::Site.all.each do |site|
      site.init_users_and_roles
    end    
  end

  desc "Update the on sale value for all products and variants"
  task :update_products_on_sale => :environment do    
    Caboose::Product.update_on_sale
  end
    
  desc "Create media categories for existing products on all sites"
  task :create_product_media_categories => :environment do
    sites = Caboose::Site.where(:use_store => true).all.each do |s|
      puts "Processing categories for " + s.description
      # Create the parent level Media category if it doesn't exist
      media_category = Caboose::MediaCategory.where(:name => "Media", :site_id => s.id).where("parent_id IS NULL").exists? ? Caboose::MediaCategory.where(:name => "Media", :site_id => s.id).where("parent_id IS NULL").last : Caboose::MediaCategory.new
      media_category.name = "Media"
      media_category.site_id = s.id
      media_category.save
      # Create the Products category if it doesn't exist
      product_category = Caboose::MediaCategory.where(:name => "Products", :site_id => s.id).exists? ? Caboose::MediaCategory.where(:name => "Products", :site_id => s.id).last : Caboose::MediaCategory.new
      product_category.parent_id = media_category.id
      product_category.name = "Products"
      product_category.site_id = s.id
      product_category.save
      # Create new category for each product
      Caboose::Product.where(:site_id => s.id).all.each do |p|
        puts "Creating media category for " + p.title
        p_category = Caboose::MediaCategory.where(:name => p.title, :site_id => s.id).exists? ? Caboose::MediaCategory.where(:name => p.title, :site_id => s.id).last : Caboose::MediaCategory.new
        p_category.name = p.title
        p_category.parent_id = product_category.id
        p_category.site_id = s.id
        p_category.save
        p.media_category_id = p_category.id
        p.save
      end
    end
  end

  desc "Migrate product images to media"
  task :migate_product_images_to_media => :environment do
    Caboose::ProductImage.where("image_file_name is not null AND media_id IS NULL").reorder("id DESC").all.each do |product_image|
      next if product_image.product.nil?
      puts "Saving media for Product Image " + product_image.id.to_s
      m = nil
      m = Caboose::Media.where(:id => product_image.media_id).first
      m = Caboose::Media.create(:media_category_id => product_image.product.media_category_id) if m.nil?
      product_image.media_id = m.id
      product_image.save
      m.original_name = product_image.image_file_name
      m.name = Caboose::Media.upload_name(m.original_name)      
      m.image = URI.parse(product_image.image.url(:original))
      m.processed = true
      m.save
    end
  end

  
  desc "Create a new lite site"
  task :create_site => :environment do
    puts "\n"
    puts "--------------------------------------------------------------------------------\n"
    puts "Create a new Nine Lite site\n"
    puts "--------------------------------------------------------------------------------\n"

    site_name = ''
    while site_name.nil? || site_name.strip.length == 0 do
      STDOUT.puts "What is the name of the site?"
      site_name = STDIN.gets.chomp
    end
    puts "\n"
    
    use_store = ''
    while use_store.nil? || (use_store.downcase != 'y' && use_store.downcase != 'n') do 
      STDOUT.puts "E-commerce? (y/n)"
      use_store = STDIN.gets.chomp
    end
    puts "\n"
    
    use_mls = ''
    while use_mls.nil? || (use_mls.downcase != 'y' && use_mls.downcase != 'n') do
      STDOUT.puts "MLS? (y/n)"
      use_mls = STDIN.gets.chomp
    end
    puts "\n"
    
    helper = SiteHelper.new    
    helper.create_site(site_name, use_store.downcase == 'y', use_mls.downcase == 'y')
    
    puts "\n"
    puts "--------------------------------------------------------------------------------\n"
    puts "Choo! Choo! Your site is set up!\n"
    puts "--------------------------------------------------------------------------------\n"    
  end

  desc "Create blocks for new site"
  task :create_site_blocks => :environment do
    puts "\n"
    puts "--------------------------------------------------------------------------------\n"
    puts "Create blocks for new site\n"
    puts "--------------------------------------------------------------------------------\n"

    input = ''
    STDOUT.puts "What is the name of the site?"
    input = STDIN.gets.chomp
    puts "\n"

    input2 = ''
    STDOUT.puts "E-commerce? (y/n)"
    input2 = STDIN.gets.chomp
    puts "\n"

    if !input.blank? && !input2.blank?
      helper = SiteHelper.new(input,"0",input2)
      helper.create_site_blocks

      puts "\n"
      puts "--------------------------------------------------------------------------------\n"
      puts "Choo! Choo! Your blocks have been created!\n"
      puts "--------------------------------------------------------------------------------\n"
    else
      puts "Invalid site name."
    end
  end
    
  desc "Reprocess media images"
  task :reprocess_media_images => :environment do    
    Caboose::Media.where("image_file_name is not null").reorder(:id).all.each do |m|
      m.delay(:queue => 'caboose_media').reprocess_image            
    end
  end
  
  desc "Migrate block images and files to media"
  task :migrate_block_assets_to_media => :environment do
    Caboose::Block.where("image_file_name is not null and media_id is null").reorder(:id).all.each do |b|                
      b.delay(:queue => 'caboose_media').migrate_media
    end  
    Caboose::Block.where("file_file_name is not null and media_id is null").reorder(:id).all.each do |b|
      b.delay(:queue => 'caboose_media').migrate_media
    end
    Caboose::BlockType.where(:id => 19).update_all('name' => 'image2')    
    Caboose::Block.where(:block_type_id => 19).update_all('name' => 'image2')
  end
        
  desc "Update expired caches and cache pages that aren't cached"
  task :cache_pages => :environment do    
    Caboose::PageCacher.delay(:queue => 'caboose_cache').refresh    
  end
  
  desc "Cache all pages"
  task :cache_all_pages => :environment do    
    Caboose::PageCacher.delay(:queue => 'caboose_cache').cache_all    
  end
  
  desc "Run rspec tests on Caboose"
  task :test => :environment do    
    system("rspec #{Caboose::root}/spec")    
  end
    
  desc "Creates/verifies that all database tables and fields are correctly added."
  task :db => :environment do
    Caboose::schemas.each do |schema_class|
      S = schema_class.constantize
      S.create_schema
      S.load_data
    end
      
    #Caboose::Schema.create_schema
    #Caboose::Schema.load_data    
    #if class_exists?('Schema')
    #  Schema.create_schema
    #  Schema.load_data
    #end
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
  task :reset_admin_pass, [:site_name] => :environment do |t, args|  
    site = Caboose::Site.where(:name => args.first).first
    if site.nil?
      puts "Error: can't find a site with that name."
      return
    end    
    admin_user = Caboose::User.where(:username => 'admin', :site_id => site.id).first
    if admin_user.nil?
      puts "Error: can't find admin user for site #{site.name}."
      return
    end
    admin_user.password = Digest::SHA1.hexdigest(Caboose::salt + 'caboose')
    admin_user.save    
    puts "Password reset successfully for the admin user for site #{site.name}."
  end
  
  desc "Verify store products have a default variant"
  task :verify_variants_exist => :environment do    
    query = ["select id from store_products where id not in (select distinct product_id from store_variants) order by site_id, status"]    
    rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, query))    
    return if rows.nil? || rows.count == 0
    
    rows.each do |row|
      p = Caboose::Product.find(row[0])
      v = Caboose::Variant.new
      v.product_id = p.id 
      v.option1 = p.default1 if p.option1
      v.option2 = p.default2 if p.option2
      v.option3 = p.default3 if p.option3
      v.status  = 'Active'
      v.save
    end    
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
  
  desc "Set invoice numbers"
  task :set_invoice_numbers => :environment do
    
    Caboose::Site.all.each do |site|
      next if !site.use_store
      n = site.store_config.starting_invoice_number
      Caboose::Invoice.where("invoice_number is null and status <> 'cart'").reorder(:id).all.each do |inv|
        i.invoice_number = n
        i.save
        n = n + 1
      end
    end
  end
  
  desc "Remove invalid variant images"
  task :remove_invalid_variant_images => :environment do
    
    Caboose::Product.reorder(:id).all.each do |p|
      ids = p.product_images.collect{ |img| img.id }
      p.variants.each do |v|
        v.product_image_variants.all.each do |piv|
          piv.destroy if !ids.include?(piv.product_image_id)
        end
      end
    end
    
  end
  
  desc "Set post slugs and URIs"
  task :set_post_slugs => :environment do
    Caboose::Post.where("slug is null or uri is null").all.each do |p|
      p.set_slug_and_uri(p.title)      
    end
  end
  
  desc "Create blocsk for posts that were on the old post system"
  task :set_post_blocks => :environment do
    Caboose::Post.where("slug is null or uri is null").all.each do |p|
      p.set_slug_and_uri(p.title)      
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
      
      rows = nil
      begin
        rows = c.execute("select nextval('#{tbl}_id_seq')")
      rescue
        next
      end
        
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
  task :purl, [:filename] => :environment do |t, args|
    
    # PURL a single file
    if args.filename
      dest = "#{Rails.root}/tmp/#{args.filename}"
      
      # Compile the file
      puts "Compiling #{args.filename}..."
      File.write(dest, Uglifier.compile(Rails.application.assets.find_asset(args.filename).to_s))
      
      # Copy the file from dest to s3/assets
      puts "Copying #{args.filename} to s3..."
      config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))['production']    
      AWS.config({ :access_key_id => config['access_key_id'], :secret_access_key => config['secret_access_key'] })                     
      bucket = AWS::S3::Bucket.new(config['bucket'])
      obj = bucket.objects["assets/#{args.filename}"]
      obj.write(:file => dest, :acl => :public_read)
      
      # Remove the temp file
      puts "Cleaning up..."
      `rm -rf #{dest}`      
    
    else # Otherwise do a full PURL
    
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
  end
   
  desc "Create .gz versions of assets"
  task :gzip => :environment do
    zip_types = /\.(?:css|js)$/
    public_assets = File.join(Rails.root, "public", Rails.application.config.assets.prefix)

    Dir["#{public_assets}/**/*"].each do |f|
      next unless f =~ zip_types

      mtime = File.mtime(f)
      gz_file = "#{f}.gz"
      next if File.exist?(gz_file) && File.mtime(gz_file) >= mtime

      File.open(gz_file, "wb") do |dest|
        gz = Zlib::GzipWriter.new(dest, Zlib::BEST_COMPRESSION)
        gz.mtime = mtime.to_i
        IO.copy_stream(open(f), gz)
        gz.close
      end

      File.utime(mtime, mtime, gz_file)
    end
  end

  # Hook into existing assets:precompile task
  Rake::Task["assets:precompile"].enhance do
    Rake::Task["assets:gzip"].invoke
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
