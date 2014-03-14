require 'spec_helper'

describe Worker do

  let(:balancer) { ConcurrencyBalancer.new }

  context 'using the sequential queue' do
    let(:ontology) { create :single_unparsed_ontology, iri: 'http://example.com/test/sequential_parse' }
    let(:version) { ontology.versions.last }

    before do
      begin
        balancer.mark_as_finished_processing(ontology.iri)
      rescue ConcurrencyBalancer::UnmarkedProcessingError
      end
      balancer.mark_as_processing_or_complain(ontology.iri)
      OntologyVersion.any_instance.stubs(:raw_path!).returns(
        Rails.root + 'test/fixtures/ontologies/clif/sequential_parse.clif')
    end

    after do
      balancer.mark_as_finished_processing(ontology.iri)
      OntologyVersion.any_instance.unstub(:raw_path!)
    end

    context 'exceeding the parallel try count of an already marked iri job' do
      it 'should put the correct job in the sequential queue' do
        Sidekiq::Testing.fake! do
          rest_args = ['record', OntologyVersion.to_s, 'parse', version.id]
          Worker.new.perform(ConcurrencyBalancer::MAX_TRIES,
            *rest_args)
          expect(SequentialWorker.jobs.first['args']).to eq([1, *rest_args])
        end
      end
    end

    context 'not exceeding the parallel try count of an already marked iri job' do
      it 'should put the correct job in the queue once again' do
        Sidekiq::Testing.fake! do
          rest_args = ['record', OntologyVersion.to_s, 'parse', version.id]
          Worker.new.perform(ConcurrencyBalancer::MAX_TRIES-1,
            *rest_args)
          expect(Worker.jobs.first['args']).to eq([
            ConcurrencyBalancer::MAX_TRIES, *rest_args])
        end
      end
    end
  end

end
