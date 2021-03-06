namespace :porthos do
  
  desc "Copy all static porthos files to "
  task :copy_dependencys do
    printf "Warning this will overwrite any changes done. Continue? [y/n]"
    if STDIN.gets.chomp == 'y'
      ['config/initializers', 
       'config/locales',
       'vendor/plugins',
       'solr',
       'app/views/pages'].each { |dir| find_and_copy_files(dir) }
      system("cp -f #{File.join(plugin_path, 'config', 'sunspot.yml')} #{File.join(app_path, 'config', 'sunspot.yml')}")
    end
  end
  
  desc "Symlink porthos public files"
  task :symlink_public_dirs do
    mkdir File.join(app_path, 'public/graphics') unless File.exists?(File.join(app_path, 'public/graphics'))
    ['public/graphics/porthos', 'public/javascripts/porthos', 'public/stylesheets/porthos', 'public/swf'].each do |dir|
      origin, destination = File.join(plugin_path, dir), File.join(app_path, dir)
      unless File.exists?(destination)
        system("ln -s #{origin} #{destination}")
        printf "Linked #{destination} to #{origin}\n"
      else
        printf "#{destination} already linked\n"
      end
    end
  end
  
  
  desc "Update Porthos"
  task :update do
    printf "Do you want to overwrite all public files in the porthos directorys (stylesheets / javascripts / graphics) [y/n] "
    if STDIN.gets.chomp == 'y'
      Rake::Task["porthos:copy_dependencys"].invoke
    end
  end
  
  desc "Install porthos"
  task :install do
    
    printf "\n\033[1m\033[41mPorthos requires Rails 2.3.10\033[0m\nAre you sure this project is using Rails 2.3.10? [y/n] "
    exit unless STDIN.gets.chomp == 'y'
    
    if File.exists?("#{app_path}/assets")
      printf "Porthos looks to be installed, sure you want to continue? [y/n] "
      exit unless STDIN.gets.chomp == 'y'
    else
      mkdir File.join(app_path, 'assets')
    end
      
    Rake::Task["porthos:copy_dependencys"].invoke      
    Rake::Task["porthos:symlink_public_dirs"].invoke      
        
    printf "Do you want to patch routes.rb and replace environment.rb to add porthos routes and porthos setup? [y/n] "
    if STDIN.gets.chomp == 'y'
      gsub_file 'config/routes.rb', /(#{Regexp.escape('ActionController::Routing::Routes.draw do |map|')})/mi do |match|
        "#{match}\n  map.routes_from_plugin(:porthos)\n"
      end

      rm 'config/environment.rb'
      cp 'vendor/plugins/porthos/config/environment.rb', 'config/environment.rb'
    end
    
    printf "Run porthos migrations? Make sure you configured config/database.yml before continuing [y/n] "
    if STDIN.gets.chomp == 'y'
      Rake::Task["porthos:install_database"].invoke
    end
  end
  
  desc "Load default db"
  task :install_database do
    printf "This will overwrite Rails.root/db/schema.rb and Rails.root/db/seeds.rb, ok? [y/n] "
    if STDIN.gets.chomp == 'y'      
      schema_template_file = 'db/schema.rb'
      seeds_template_file = 'db/seeds.rb'
      system("cp -f #{File.join(plugin_path, schema_template_file)} #{File.join(app_path, schema_template_file)}")
      system("cp -f #{File.join(plugin_path, seeds_template_file)} #{File.join(app_path, seeds_template_file)}")
      Rake::Task["db:setup"].invoke
      system("rm #{File.join(app_path, schema_template_file)}")
      system("rm #{File.join(app_path, seeds_template_file)}")
    end
  end
  
  desc "Reset MemCache node cache"
  task (:reset_node_cache => :environment) do
    require "porthos/routing.rb"
    memcache = Porthos::Routing::MemCacheStore.new
    memcache.store({})
  end
end

private

  def gsub_file(destination, regexp, *args, &block)
    content = File.read(destination).gsub(regexp, *args, &block)
    File.open(destination, 'wb') { |file| file.write(content) }
  end

  def plugin_path
    "#{File.dirname(__FILE__)}/../.."
  end

  def app_path
    Rails.root
  end

  def find_and_copy_files(dir)
    mkdir File.join(app_path, dir) unless File.exists? File.join(app_path, dir)
    Dir.foreach(File.join(plugin_path, dir)) do |entry|
      origin      = File.join(plugin_path, dir, entry)
      destination = File.join(app_path, dir, entry)
      unless File.basename(entry)[0,1] == '.'
        if File.file? origin
          system("cp -f #{origin} #{destination}") # overwrite any existing files
        elsif File.directory? origin
          mkdir destination unless File.exists? destination
          find_and_copy_files File.join(dir, entry)
        end
      end
    end
  end