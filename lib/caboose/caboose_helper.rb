
class CabooseHelper
  
  def initialize(vars)    
    @vars = vars
    @vars['CABOOSE_SALT'] = Digest::SHA1.hexdigest(DateTime.now.to_s) if @vars['|CABOOSE_SALT|'].nil?
  end
  
  def init_all        
    init_skeleton_files
    init_gem
    init_app_config    
    init_initializer
    init_routes    
    init_session
    remove_public_index
  end
  
  # Copies all the files in the sample directory to the host application
  def init_skeleton_files
    gem_root = Gem::Specification.find_by_name('caboose-cms').gem_dir    
    skeleton_root = File.join(gem_root,'lib','sample_files')
    
    Find.find(skeleton_root).each do |file|    
      next if File.directory?(file)  
      file2 = file.gsub(skeleton_root, '')
      file2 = File.join(Rails.root, file2)            
      FileUtils.cp(file, file2)
      
      # Replace any variables
      f = File.open(file2, 'rb')
      str = f.read
      f.close
      @vars.each { |k,v| str.gsub!("|#{k}|",v) }      
      File.open(file2, 'w') { |f| f.write(str) }      
    end  
  end
  
  # Add the gem to the Gemfile
  def init_gem
    puts "Adding the caboose gem to the Gemfile... "
    filename = File.join(@app_path,'Gemfile')
    return if !File.exists?(filename)    
    return if !@force
    
    file = File.open(filename, 'rb')
    str = file.read
    file.close
    str2 = ""
    str.each_line do |line|
      if (!line.strip.start_with?('#') && (!line.index("gem 'caboose-cms'").nil? || !line.index('gem "caboose-cms"').nil?))
        str2 << "##{line}"
      else
        str2 << line
      end
    end
    str2 << "gem 'caboose-cms', '= #{Caboose::VERSION}'\n"
    str2 << "gem 'asset_sync'\n"
    str2 << "gem 'unf'\n"
    str2 << "gem 'aws-sdk'\n"

    File.open(filename, 'w') {|file| file.write(str2) }
  end
    
  # Require caboose in the application config
  def init_app_config
    puts "Requiring caboose in the application config..."
    
    filename = File.join(@app_path,'config','application.rb')
    return if !File.exists?(filename)    
          
    file = File.open(filename, 'rb')
    contents = file.read
    file.close    
    if (contents.index("require 'caboose'").nil?)
      arr = contents.split("require 'rails/all'", -1)
      str = arr[0] + "\nrequire 'rails/all'\nrequire 'caboose'\n" + arr[1]      
      str.gsub!("config.assets.initialize_on_precompile = false", "config.assets.initialize_on_precompile

      
      File.open(filename, 'w') { |file| file.write(str) }
    end
  end
  
  # Removes the public/index.html file from the rails app
  def remove_public_index
    puts "Removing the public/index.html file... "
    
    filename = File.join(@app_path,'public','index.html')
    return if !File.exists?(filename)
    File.delete(filename)
  end
  
  # Inits the caboose initializer file  
  def init_initializer
    puts "Initializing the salt variable in the caboose initializer file..."
    
    filename = File.join(@app_path,'config','initializers','caboose.rb')
    return if File.exists?(filename)
    
    Caboose::salt = Digest::SHA1.hexdigest(DateTime.now.to_s)
    
    file = File.open(filename, 'rb')
    contents = file.read
    file.close
    contents.gsub('|CABOOSE_SALT|', Caboose::salt)    
    File.open(filename, 'w') { |file| file.write(contents) }
  end

  # Adds the routes to the host app to point everything to caboose
  def init_routes
    puts "Adding the caboose routes..."
    
    filename = File.join(@app_path,'config','routes.rb')
    return if !File.exists?(filename)    
    
    str = "" 
    str << "\t# Catch everything with caboose\n"  
    str << "\tmount Caboose::Engine => '/'\n"
    str << "\tmatch '*path' => 'caboose/pages#show'\n"
    str << "\troot :to      => 'caboose/pages#show'\n"    
    file = File.open(filename, 'rb')
    contents = file.read
    file.close    
    if (contents.index(str).nil?)
      arr = contents.split('end', -1)
      str2 = arr[0] + "\n" + str + "\nend" + arr[1]
      File.open(filename, 'w') {|file| file.write(str2) }
    end    
  end

  # Changes session storage to active record
  def init_session
    puts "Setting the session config..."    
    
    lines = []
    str = File.open(File.join(@app_path,'config','initializers','session_store.rb')).read 
    str.gsub!(/\r\n?/, "\n")
    str.each_line do |line|
      line = '#' + line if !line.index(':cookie_store').nil?        && !line.start_with?('#')
      line[0] = ''      if !line.index(':active_record_store').nil? && line.start_with?('#')
      lines << line.strip
    end
    str = lines.join("\n")
    File.open(File.join(@app_path,'config','initializers','session_store.rb'), 'w') {|file| file.write(str) }
  end
end
