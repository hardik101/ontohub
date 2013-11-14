# 
# Controller for ontologies
# 
class OntologiesController < InheritedResources::Base

  include RepositoryHelper

  belongs_to :repository, finder: :find_by_path!
  respond_to :json, :xml
  has_pagination
  has_scope :search
  actions :index, :show, :edit, :update

  before_filter :check_write_permission, :except => [:index, :show, :oops_state]

  def index
    if in_repository?
      @count = end_of_association_chain.total_count
      render :index_ontology
    else
      @count = resource_class.count
      render :index_global
    end
  end
  

  def new
    @ontology_version = build_resource.versions.build
    @c_vertices = []
    vert = Category.first
    if vert
      @c_vertices = vert.roots.first.children
    end
  end

  def edit
    @ontology = resource
    @c_vertices = []
    vert = Category.first
    if vert
      @c_vertices = vert.roots.first.children
    end
  end

  def update
    resource.category_ids = user_selected_categories
    super
  end

  def create
    @version = build_resource.versions.first
    @version.user = current_user
    super
    resource.category_ids = user_selected_categories
  end
  
  def show
    @content_object = :ontology

    if !params[:repository_id]
      # redirect for legacy routing
      ontology = Ontology.find params[:id]
      redirect_to [ontology.repository, ontology]
      return
    end

    respond_to do |format|
      format.html do
        if !resource.distributed?
          redirect_to repository_ontology_entities_path(parent, resource,
                       :kind => resource.entities.groups_by_kind.first.kind)
        else
          redirect_to repository_ontology_children_path(parent, resource)
        end
      end
      format.json do
        respond_with resource
      end
    end
  end

  def retry_failed
    end_of_association_chain.retry_failed
    redirect_to [parent, :ontologies]
  end
  
  def oops_state
    respond_to do |format|
      format.json do
        respond_with resource.versions.current.try(:request)
      end
    end
  end


  protected
  
  def build_resource
    @ontology ||= begin
      type  = (params[:ontology] || {}).delete(:type)
      clazz = type=='DistributedOntology' ? DistributedOntology : SingleOntology
      @ontology = clazz.new params[:ontology]
      @ontology.repository = parent
      @ontology
    end
  end

  def check_write_permission
    authorize! :write, parent
  end

  def build_categories_tree(vertex)
    @a ||= []
    vertex.children.each { |child| build_categories_tree(child) unless child.children.empty?; @a << child }
    @a
  end

  def user_selected_categories
    params[:category_ids].keys unless params[:category_ids].nil?
  end

end

