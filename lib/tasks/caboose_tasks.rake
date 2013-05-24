# desc "Explaining what the task does"
# task :caboose do
#   # Task goes here
# end

def init_file(filename, str = nil)
  if !File.exists(filename)
    File.open(filename, 'w') do |file|
      file.write str unless str.nil? 
    end
  end  
end

desc "Initialize a caboose installation"
task :init do

  # Add the js and css files
  init_file(Rails.root.join('app','assets','javascripts','caboose_before.js'))
  init_file(Rails.root.join('app','assets','javascripts','caboose_after.js'))
  init_file(Rails.root.join('app','assets','stylesheets','caboose_before.css'))
  init_file(Rails.root.join('app','assets','stylesheets','caboose_after.css'))
  
  # Add the caboose initializer file
  str = ""
  str << "Caboose::salt = 'CHANGE THIS TO A UNIQUE STRING!!!'\n\n"
  str << "Caboose::assets_path = Rails.root.join('app', 'assets', 'caboose')\n\n"
  str << "Caboose::plugins = []\n"
  init_file(Rails.root.join('config','initializers','caboose.rb'), str)

end
