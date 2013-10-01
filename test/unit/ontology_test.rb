require 'test_helper'

class OntologyTest < ActiveSupport::TestCase
  should belong_to :language
  should belong_to :logic
  should belong_to :ontology_version
  should have_many :versions
  should have_many :comments
  should have_many :sentences
  should have_many :entities
  
  should have_db_index(:iri).unique(true)
  should have_db_index([:repository_id, :path]).unique(true)
  should have_db_index(:state)
  should have_db_index(:language_id)
  should have_db_index(:logic_id)

  should strip_attribute :name
  should strip_attribute :iri
  should_not strip_attribute :description

  context 'Validations' do
    ['http://example.com/', 'https://example.com/', 'file://path/to/file'].each do |val|
      should allow_value(val).for :iri
    end
  end

  ['', 'fooo'].each do |val|
    should_not allow_value(val).for :iri
  end
  
  context 'ontology instance' do
    setup do
      @ontology = FactoryGirl.create :ontology
    end
    
    context 'with name' do
      setup do
        @name = "fooo"
        @ontology.name = @name
      end
      should 'have to_s' do
        assert_equal @name, @ontology.to_s
      end
    end
    
    context 'without name' do
      setup do
        @ontology.name = nil
      end
      should 'have to_s' do
        assert_equal @ontology.iri, @ontology.to_s
      end
    end
  end
  
  context 'checking ordering of Ontology list' do
    setup do
      Ontology::States::STATES.each do |state|
        FactoryGirl.create :ontology, state: state
      end
      @ontology_list = Ontology.list
      @done_state = "done"
    end

    should 'list done ontologies first' do
      assert_equal @done_state, @ontology_list.first.state
    end
  end

end
