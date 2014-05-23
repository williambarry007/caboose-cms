require 'find'

class CabooseHelper
  
  def initialize(vars)    
    @vars = vars
    @vars['APP_NAME'] = @vars['APP_NAME'].downcase.capitalize
    @vars['CABOOSE_SALT'] = Digest::SHA1.hexdigest(DateTime.now.to_s) if @vars['CABOOSE_SALT'].nil?
    @vars['CABOOSER_VERSION'] = Caboose::VERSION if @vars['CABOOSE_VERSION'].nil?
  end
  
  def create_app
    # Create the rails app
    puts "Creating the rails app..."
    `rails new #{@vars['APP_NAME'].downcase} -d=postgresql`

    # Do the caboose init
    init_skeleton_files
    remove_public_index
  end
  
  # Copies all the files in the sample directory to the host application
  def init_skeleton_files
    puts "Adding files to rails app..."
    
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
  
  # Removes the public/index.html file from the rails app
  def remove_public_index
    puts "Removing the public/index.html file... "
    
    filename = File.join(@app_path,'public','index.html')
    return if !File.exists?(filename)
    File.delete(filename)
  end
  
end
