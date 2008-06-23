# == Schema Information
# Schema version: 76
#
# Table name: pages
#
#  id                      :integer(11)   not null, primary key
#  title                   :string(255)   
#  description             :text          
#  page_layout_id          :integer(11)   
#  layout_class            :string(255)   
#  column_count            :integer(11)   
#  published_on            :datetime      
#  created_at              :datetime      
#  updated_at              :datetime      
#  slug                    :string(255)   
#  type                    :string(255)   
#  position                :integer(11)   
#  parent_id               :integer(11)   
#  parent_type             :string(255)   
#  default_child_layout_id :integer(11)   
#

class Page < ActiveRecord::Base
  
  validates_presence_of :title, :page_layout_id

  belongs_to  :parent,      :polymorphic => true
  has_one     :node,        :as    => :resource
  has_many    :contents,    :order => :position,  :conditions => ["contents.parent_id IS NULL"], :dependent => :destroy
  belongs_to  :page_layout
  belongs_to  :default_child_layout, :foreign_key => 'default_child_layout_id', :class_name => 'PageLayout'
  has_many :comments, :as => :commentable, :order => 'comments.created_at'
  
  has_finder :published, :conditions => "published_on <= CURRENT_DATE"
  has_finder :published_within, lambda { |from, to| { :conditions => ["published_on BETWEEN ? AND ?", from.to_s(:db), to.to_s(:db)] } }

  has_finder :active,   :conditions => "active = 1"
  has_finder :inactive, :conditions => "active = 0"
  has_finder :include_restricted, lambda {|restricted| { :conditions => ['restricted = ? or restricted = 0', restricted]} }

  before_validation_on_create :set_default_layout, :set_layout_and_parent, :set_inactive

  before_create :set_published_on
  before_validation_on_update :set_layout_and_parent 
  before_save   :set_layout_attributes, :generate_slug
  after_create  :insert_default_contents

  acts_as_list :scope => 'parent_id = \'#{parent_id}\' and parent_type = \'#{parent_type}\''

  acts_as_taggable
  
  is_indexed :fields => ['title', 'description', 'slug', 'type'], :concatenate => [{
    :class_name => 'Textfield', :field => 'body', :as => 'body', 
    :association_sql => "LEFT OUTER JOIN contents ON (pages.id = contents.page_id) LEFT OUTER JOIN textfields ON (textfields.id = contents.resource_id AND contents.resource_type = 'Textfield')"
  }]
  
  attr_accessor :preset_id
  
  def body
    contents.collect {|c| c.resource.body if c.resource_type == 'Textfield' }.join
  end
  
  def published?
    published_on <= Time.now.end_of_day
  end

  def child?
    not parent_type.blank? and not parent_id.blank?
  end

  def part_of_collection?
    child? and parent_type == 'Page'
  end

private

  def set_inactive
    self.active = !self.child?
    true
  end

  def generate_slug
    self.slug = title.to_url
  end

  def set_published_on
    self.published_on = Time.now.at_midnight if published_on.blank?
  end
  
  def set_layout_and_parent
    unless preset_id.blank?
      page_preset = PagePreset.find(preset_id)
      self.page_layout_id = page_preset.page_layout_id
      self.parent_id      = page_preset.page_collection_id
    end
    self.parent = Page.find(self.parent_id) if self.parent_id and not self.parent_type
  end

  def set_layout_attributes    
    contents.update_all("column_position = #{page_layout.columns}", "column_position > #{page_layout.columns}") unless column_count == page_layout.columns or column_count.blank?
    self.layout_class = page_layout.css_id
    self.column_count = page_layout.columns
  end
  
  def set_default_layout
    self.page_layout = parent.default_child_layout if child? and parent.respond_to?(:default_child_layout)
  end
  
  def insert_default_contents
    self.page_layout.default_contents.each do |d|
      c = Content.new
      c.resource_type, c.resource_id, c.column_position = d.resource_type, d.resource_id, d.column_position
      self.contents << c
    end if self.page_layout and self.page_layout.default_contents.any?
  end
  
end
