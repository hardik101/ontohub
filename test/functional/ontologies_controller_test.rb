require 'test_helper'

class OntologiesControllerTest < ActionController::TestCase
  
  should_map_resources :ontologies
  should route(:get, "/ontologies/bulk").to(:controller=> :ontologies, :action => :bulk)
  
  context 'Ontology Instance' do
    setup do
      @ontology = Factory :ontology
      @user     = Factory :user
      
      2.times { Factory :entity, :ontology => @ontology }
    end
    
    context 'on GET to index' do
      context 'without search' do
        setup do
          get :index
        end
        
        should respond_with :success
        should assign_to(:search).with{ nil }
        should render_template :index
        should render_template 'ontologies/_ontology'
      end
      
      context 'with search' do
        setup do
          @search = @ontology.name
          get :index, :search => @search
        end
        
        should respond_with :success
        should assign_to(:search).with{ @search }
        should render_template :index
        should render_template 'ontologies/_ontology'
      end
    end
    
    context 'on GET to show' do
      setup do
        get :show, :id => @ontology.to_param
      end
      
      should respond_with :success
      should assign_to :grouped_kinds
      should render_template :show
    end
    
    context 'signed in' do
      setup do
        sign_in @user
      end
      
      context 'on GET to bulk' do
        setup do
          get :bulk
        end
        
        should respond_with :success
        should render_template :bulk
      end
      
      context 'on GET to new' do
        setup do
          get :new
        end
        
        should respond_with :success
        should assign_to :version
        should render_template :new
      end
      
      context 'on POST to create' do
        
        context 'with invalid input' do
          context 'without format' do
            setup do
              post :create, :ontology => {
                uri: 'fooo',
                versions_attributes: [{
                  source_uri: ''
                }],
              }
            end
            
            should respond_with :success
            should assign_to :version
            should render_template :new
          end
          
          context 'with format :json' do
            setup do
              post :create, :format => :json, :ontology => {
                uri: 'fooo',
                versions_attributes: [{
                  source_uri: ''
                }],
              }
            end
            
            should respond_with :unprocessable_entity
          end
        end
        
        context 'with valid input' do
          context 'without format' do
            setup do
              OntologyVersion.any_instance.expects(:parse_async).once
              
              post :create, :ontology => {
                uri: 'http://example.com/dummy.ontology',
                versions_attributes: [{
                  source_uri: 'http://example.com/dummy.ontology'
                }],
              }
            end
            
            should assign_to :version
            should respond_with :redirect
          end
          
          context 'with format :json' do
            setup do
              OntologyVersion.any_instance.expects(:parse_async).once
              
              post :create, :format => :json, :ontology => {
                uri: 'http://example.com/dummy.ontology',
                versions_attributes: [{
                  source_uri: 'http://example.com/dummy.ontology'
                }],
              }
            end
            
            should assign_to :version
            should respond_with :created
          end
        end
      end
    end
    
    context 'owned by signed in user' do
      setup do
        sign_in @user
        @ontology.permissions.create! \
          :role    => 'owner',
          :subject => @user
      end
      
      context 'on GET to edit' do
        setup do
          get :edit, :id => @ontology.to_param
        end
        
        should respond_with :success
        should render_template :edit
      end
      
      context 'on PUT to update' do
        setup do
          put :update, 
            :id   => @ontology.to_param,
            :name => 'foo bar'
        end
        
        should redirect_to("show action"){ @ontology }
      end
    end
  end
  
end
