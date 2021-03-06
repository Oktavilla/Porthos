# require "#{Rails.root}/app/views/pages/templates/default/default_renderer"
class PagesController < ApplicationController
  include Porthos::Public
  before_filter :require_node

  before_filter :only => :preview do |c|
    user = c.send :current_user
    raise ActiveRecord::RecordNotFound if user == :false or !user.admin?
  end

  layout 'public'

  def index
    @field_set = @node.field_set
    template = @field_set ? @field_set.template : PageTemplate.default
    @renderer = @field_set.renderer(:index, params)

    respond_to do |format|
      format.html { render :template => template.views.index }
      format.rss  { render :template => template.views.index, :layout => false }
    end
  end

  def show
    @page = Page.find(params[:id], :include => [:custom_attributes, :custom_associations, :fields])
    @renderer = @page.field_set.renderer(:show, @page, params)

    login_required if @page.restricted?

    respond_to do |format|
      format.html { render :template => @page.field_set.template.views.show }
    end
  end

  def preview
    @page = Page.find(params[:id])
    @renderer = @page.field_set.renderer(:show, @page, params)
    respond_to do |format|
      format.html { render :template => @page.field_set.template.views.show }
    end
  end

  def search
    filters = params[:filters] || {}
    @field_set = @node.field_set
    search_query = params[:query] if params[:query].present?
    if search_query.present? or filters.any?
      field_set = @field_set
      @search = Page.search do
        keywords search_query
        if filters.any?
          dynamic :custom_attributes do
            filters.each do |key, value|
              with(key.to_sym, value) unless value.blank?
            end
          end
        end
        with(:is_active, true)
        with(:is_restricted, false)
        with(:field_set_id, field_set.id) if field_set
        with(:published_on).less_than Time.now
      end
      @query, @filters = params[:query], filters
    end
    respond_to do |format|
      format.html { render :template => (@field_set ? @field_set.template.views.search : PageTemplate.default.views.search) }
    end
  end

  # POST
  def comment
    @page    = Page.find(params[:id])
    @comment = @page.comments.new(params[:comment])
    @comment.ip_address, @comment.env = request.remote_ip, request.env
    respond_to do |format|
      if @comment.save
        flash[:notice] = @comment.spam ? t(:saved, :scope => [:app, :admin_comments]) : t(:published, :scope => [:app, :admin_comments])
        format.html { redirect_to (params[:return_to] || "/#{@node.slug}#comment_#{@comment.id}") }
      else
        format.html { render :action => 'show' }
      end
    end
  end

end
