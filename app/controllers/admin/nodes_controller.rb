class Admin::NodesController < ApplicationController
  include Porthos::Admin
  before_filter :login_required
  layout 'content'
  
  def index
    respond_to do |format|
      format.html do
        @root  = Node.root
        @nodes = @root ? @root.children : []
        @open_nodes = params[:nodes] ? Node.find_all_by_id(params[:nodes]) : Node.find_all_by_id(cookies[:last_opened_node])
        @trail = @open_nodes ? @open_nodes.collect{ |node| (node.ancestors || []) << node }.flatten : []
      end
      format.js do
        @node = params[:nodes] ? Node.find(params[:nodes].first, :include => :children) : Node.root
        render :partial => 'admin/nodes/list_of_nodes.html.erb', :locals => { :nodes => @node.children.sort_by { |n| n.position.to_i }, :trail => [], :place => (params[:place] || false) }
      end
    end
  end

  def show
    @node = Node.find(params[:id])
    respond_to do |format|
      format.html { redirect_to admin_nodes_path(:nodes => @node) }
      format.js { render :json => @node.to_json }
    end
  end

  def new
    @node = Node.new
    respond_to do |format|
      format.html
    end
  end
  
  def create
    @node = Node.new(params[:node])
    respond_to do |format|
      if @node.save
        format.html { redirect_to place_admin_node_path(@node) }
      else
        format.html { render :action => 'new' }
      end
    end
  end
  
  def place
    @node = Node.find(params[:id])
    @nodes = [Node.root]
    @trail = []
    respond_to do |format|
      format.html do
        redirect_to admin_nodes_path unless Node.count > 1
      end
    end
  end
  
  def edit
    @node = Node.find(params[:id])
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def update
    @node = Node.find(params[:id])
    respond_to do |format|
      if @node.update_attributes(params[:node])
        format.html do
          if params[:place] and @node.controller == 'pages'
            redirect_to admin_page_path(@node.resource_id)
          else
            redirect_to admin_nodes_path(:nodes => @node) 
          end
        end
      else
        format.html do
          unless params[:place]
            render :action => 'edit'
          else
            @nodes = Node.roots
            render :action => 'place'
          end
        end
      end
    end
  end
  
  def destroy
    @node = Node.find(params[:id])
    @node.destroy
    respond_to do |format|
      flash[:notice] = "”#{@node.name}” #{t(:deleted, :scope => [:app, :admin_nodes])}"
      format.html { redirect_to admin_nodes_path }
    end
  end
  
  def sort
    sort_nodes(params[:nodes])
    @root  = Node.root
    @nodes = @root.children
    @open_nodes = Node.find_all_by_id(params[:open_nodes]) if params[:open_nodes]
    @trail = @open_nodes ? @open_nodes.collect{ |node| (node.ancestors || []) << node }.flatten : []
    respond_to do |format|
      format.js { render :partial => 'nodes_tree.html.erb', :locals => { :nodes => @nodes, :open_nodes => @open_nodes, :trail => @trail, :place => false } }
    end
  end
  
protected
  def sort_nodes(nodes_hash)
    parent_id = nodes_hash[:id].to_i != 0 ? nodes_hash[:id] : Node.root.id
    nodes_hash.each do |key, value|
      # We want to skip non-children entry
      next if key == 'id'
      Node.update(value[:id], {
        :parent_id => parent_id,
        :position  => key.to_i+1
      })
      # Recursive step
      sort_nodes value
    end
    
  end
end
