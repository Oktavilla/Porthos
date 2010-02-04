module Porthos
  module ContentResource

    def self.included(base)
      base.cattr_accessor :view_paths
      base.class_eval <<-EOF
      
        after_update :notify_content_context
      
        self.view_paths = {
          :admin  => "/admin/contents/#{base.to_s.underscore.pluralize}/#{self.to_s.underscore}.html.erb",
          :new    => "/admin/contents/#{base.to_s.underscore.pluralize}/new",
          :edit   => "/admin/contents/#{base.to_s.underscore.pluralize}/edit",
          :public => "/pages/contents/#{base.to_s.underscore}.html.erb"
        }
      EOF
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods

      def view_path(type)
        self.class.view_path(type)
      end
      
    protected
    
      def notify_content_context
        content = Content.find(:first, :conditions => ["resource_id = ? and resource_type = ?", self.id, self.class.to_s], :include => :context)
        if content && content.context && content.context.respond_to?(:changed_at)
          content.context.update_attributes(:changed_at => Time.now)
        end
      end
    
    end

    module ClassMethods
      
      def view_path(type)
        view_paths[type.to_sym]
      end

    end
  end
end