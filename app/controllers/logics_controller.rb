# 
# Controller for Logics
# 
class LogicsController < InheritedResources::Base

  respond_to :json, :xml
  has_pagination
  has_scope :search

  load_and_authorize_resource :except => [:index, :show]
  
  def index
    super do |format|
      format.html do
        @search = params[:search]
        @search = nil if @search.blank?
      end
    end
  end

  def create
    @logic.user = current_user
    super
  end
  
  def show
    @available_tabs = [
      ['Mappings', :mappings],
      ['Supports', :supports],
      ['Ontologies', :ontologies],
    ]
    @tab = params[:tab]
    super do |format|
      format.html do
        @mappings_from = resource.mappings_from
        @mappings_to = resource.mappings_to
        @ontologies = resource.ontologies
        @relation_list ||= RelationList.new [resource, :supports],
          :model       => Support,
          :collection  => resource.supports,
          :association => :language,
          :scope       => [Language]
      end
    end
  end
  
  protected
  
  def authorize_parent
    #not needed
  end
  
end
