require 'spec_helper'

describe VCR::Middleware::Rack do
  describe '.new' do
    it 'raises an error if no cassette arguments block is provided' do
      expect {
        described_class.new(lambda { |env| })
      }.to raise_error(ArgumentError)
    end
  end

  describe '#call' do
    let(:env_hash) { { :env => :hash } }
    it 'calls the provided rack app and returns its response' do
      rack_app = mock
      rack_app.should_receive(:call).with(env_hash).and_return(:response)
      instance = described_class.new(rack_app) { |c| c.name 'cassette_name' }
      instance.call(env_hash).should == :response
    end

    it 'uses a cassette when the rack app is called' do
      VCR.current_cassette.should be_nil
      rack_app = lambda { |env| VCR.current_cassette.should_not be_nil }
      instance = described_class.new(rack_app) { |c| c.name 'cassette_name' }
      instance.call({})
      VCR.current_cassette.should be_nil
    end

    it 'sets the cassette name based on the provided block' do
      rack_app = lambda { |env| VCR.current_cassette.name.should == 'rack_cassette' }
      instance = described_class.new(rack_app) { |c| c.name 'rack_cassette' }
      instance.call({})
    end

    it 'sets the cassette options based on the provided block' do
      rack_app = lambda { |env| VCR.current_cassette.erb.should == { :foo => :bar } }
      instance = described_class.new(rack_app, &lambda do |c|
        c.name    'c'
        c.options :erb => { :foo => :bar }
      end)

      instance.call({})
    end

    it 'yields the rack env to the provided block when the block accepts 2 arguments' do
      instance = described_class.new(lambda { |env| }, &lambda do |c, env|
        env.should == env_hash
        c.name    'c'
      end)

      instance.call(env_hash)
    end
  end
end
