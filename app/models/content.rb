class Content < ActiveRecord::Base
  belongs_to :context,  :polymorphic => true
  belongs_to :resource, :polymorphic => true
  belongs_to :content_collection, :foreign_key => 'parent_id'
  has_many :restrictions
  named_scope :active, :conditions => ["contents.active = ?", true]

  acts_as_list :scope => 'context_id = \'#{context_id}\' AND context_type = \'#{context_type}\' AND column_position = \'#{column_position}\' AND parent_id #{(parent_id.blank? ? "IS NULL" : (" = " + parent_id.to_s))}'
  
  acts_as_settingable
  
  after_save :notify_context
  
  # Should destroy resource unless it's shared in any sence
  before_destroy do |content|
    if content.resource and not content.module? and not content.form?
      content.resource.destroy unless content.resource.has_attribute?(:shared) and content.resource.shared?
    end
  end

  # Should destroy content_collection if last child
  after_destroy do |content|
    unless content.parent_id.blank?
      content.content_collection.destroy if Content.count(:conditions => ["parent_id = ?", content.parent_id]) == 0
    end
  end

  def validate
    errors.add(:resource_type, "är inte av rätt typ") if resource_type and not self.approved_resources.include?(resource_type)
  end

  def resource_class
    @resource_class ||= resource_type.constantize
  end

  def text?
    resource_type == 'Textfield'
  end
  
  def shared?
    resource and resource.has_attribute?(:shared) and resource.shared?
  end

  def module?
    resource_type == 'ContentModule'
  end

  def form?
    resource_type == 'RegistrationForm'
  end

  def public_template
    @public_template ||= if collection?
      "/pages/contents/#{resource_type.underscore.pluralize}/collection"
    elsif form?
      "/pages/contents/registration_forms/#{resource.template}"
    else
      "/pages/contents/#{resource_type.underscore.pluralize}/#{resource_type.underscore}"
    end
  end

  def resource_template
    "admin/contents/#{resource_type.underscore.pluralize}/#{resource_type.underscore}.html.erb"
  end

  def collection_template
    "admin/contents/#{resource_type.underscore.pluralize}/collection.html.erb"
  end

  def collection?
    self.is_a?(ContentCollection)
  end

  def approved_resources
    self.class.approved_resources
  end

  def self.approved_resources
    [
      'Textfield',
      'Teaser',
      'ContentModule',
      'RegistrationForm',
      'ContentImage',
      'ContentMovie'
    ]
  end
  
  def viewable_by(user)
    !self.restrictions.detect { |r| r.denies?(user) }
  end
  
  def restricted?
    !restrictions_count.nil? && restrictions_count > 0
  end
  
  def multiple_restrictions=(_restrictions)
    self.restrictions.destroy_all
    _restrictions.each do |key|
      self.restrictions << self.restrictions.create(:mapping_key => key)
    end
  end
  
protected

  def notify_context
    context.update_attributes(:changed_at => Time.now) if context && context.respond_to?(:changed_at)
  end

end
