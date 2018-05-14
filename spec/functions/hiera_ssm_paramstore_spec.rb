require 'spec_helper'

require 'puppet/functions/hiera_ssm_paramstore'

describe TF do

  let(:function) { described_class.new }
  before(:each) do
    @context = instance_double("Puppet::LookupContext")
    allow(@context).to receive(:cache_has_key)
    allow(@context).to receive(:explain)
    allow(@context).to receive(:interpolate)
    allow(@context).to receive(:cache)
    allow(@context).to receive(:not_found)
  end

  describe "lookup_key" do
    context "Should run" do
      let(:options) {{
        'uri' => '/',
        'region' => 'us-east-1'
      }}
      let(:key) { 'encrypted' }

        it "find string" do
          expect(@context).to receive(:interpolate).with('/plain').and_return('/plain')
          expect(function.lookup_key('plain', options, @context)).to eq('value_plain')
        end

        it "find secure string" do
          expect(@context).to receive(:interpolate).with('/encrypted').and_return('/encrypted')
          expect(function.lookup_key('encrypted', options, @context)).to eq('value_encrypted')
        end

        it "not find value" do
          expect(@context).to receive(:interpolate).with('/nonexists').and_return('/nonexists')
          expect(@context).to receive(:not_found)
          expect(function.lookup_key('nonexists', options, @context)).to eq(nil)
        end

        it "find string another region" do
          options['region'] = 'us-east-2'
          expect(@context).to receive(:interpolate).with('/region2').and_return('/region2')
          expect(function.lookup_key('region2', options, @context)).to eq('ohio')
        end
      end
  end
end
