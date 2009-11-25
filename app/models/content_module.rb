# == Schema Information
# Schema version: 76
#
# Table name: content_modules
#
#  id                     :integer(11)   not null, primary key
#  name                   :string(255)   
#  template               :string(255)   
#  created_at             :datetime      
#  updated_at             :datetime      
#  available_in_page_type :string(255)   
#

class ContentModule < ActiveRecord::Base
  validates_presence_of :name, :template

  def available_templates
    @available_templates ||= self.class.find_available_templates
  end
  
  def available_page_types
    self.class.available_page_types
  end
  
  def has_settings?
    ContentModule.template_paths.collect do |path|
      path = File.join(path, template)
      return true if File.directory?(path) and File.exists?(File.join(path, "_settings.html.erb"))
    end
    false
  end
  
  def has_preview?
    ContentModule.template_paths.collect do |path|
      path = File.join(path, template)
      return true if File.directory?(path) and File.exists?(File.join(path, "_preview.html.erb"))
    end
    false
  end
  

  class << self

    def can_be_edited_by?(user)
      user.has_role?('SiteAdmin')
    end

    def can_be_created_by?(user)
      user.has_role?('SiteAdmin')
    end

    def can_be_destroyed_by?(user)
      user.has_role?('SiteAdmin')
    end
    
    def available_page_types
      ['Page', 'PageCollection']
    end
    
    def find_available_templates
      ContentModule.template_paths.collect do |path|
        Dir.entries(path).reject { |entry| entry.chars.first == '.' or !File.directory?(File.join(path, entry) ) }
      end.flatten.compact.uniq.sort
    end
    
    def template_paths
      module_paths = if File.exists?(RAILS_ROOT + '/app/views/pages/contents/modules')
        [RAILS_ROOT + '/app/views/pages/contents/modules', File.dirname(__FILE__) + '/../views/pages/contents/modules']
      else
        [File.dirname(__FILE__) + '/../views/pages/contents/modules']
      end
    end
  end

end
