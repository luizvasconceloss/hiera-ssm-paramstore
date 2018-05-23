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
    context "Should run fetching single key" do
      let(:options) {{
        'uri' => '/',
        'region' => 'us-east-1',
        'get_all' => false
      }}

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

        it "find string using another region" do
          options['region'] = 'us-east-2'
          expect(@context).to receive(:interpolate).with('/region2').and_return('/region2')
          expect(function.lookup_key('region2', options, @context)).to eq('ohio')
        end
      end
    context "Should run fetching all keys" do
      let(:options) {{
        'uri' => '/',
        'region' => 'us-east-1',
        'get_all' => true,
        'recursive' => true
      }}

      it "find string" do
        expect(@context).to receive(:interpolate).with('/plain').and_return('/plain')
        allow(@context).to receive(:cache).with({'plain' => 'value_plain'})
        expect(@context).to receive(:cached_value).with('plain').and_return('value_plain')
        expect(@context).to receive(:cache_has_key).with('plain').and_return(true)
        expect(function.lookup_key('plain', options, @context)).to eq('value_plain')
      end

      it "find secure string" do
        expect(@context).to receive(:interpolate).with('/encrypted').and_return('/encrypted')
        allow(@context).to receive(:cache).with({'encrypted' => 'value_encrypted'})
        expect(@context).to receive(:cached_value).with('encrypted').and_return('value_encrypted')
        expect(@context).to receive(:cache_has_key).with('encrypted').and_return(true)
        expect(function.lookup_key('encrypted', options, @context)).to eq('value_encrypted')
      end

      it "not find value" do
        expect(@context).to receive(:interpolate).with('/nonexists').and_return('/nonexists')
        expect(@context).to receive(:cache_has_key).with('nonexists').and_return(false)
        expect(@context).to receive(:not_found)
        expect(function.lookup_key('nonexists', options, @context)).to eq(nil)
      end

      it "find string full path" do
        options['uri'] = '/hiera/'
        expect(@context).to receive(:interpolate).with('/hiera/path').and_return('/hiera/path')
        allow(@context).to receive(:cache).with({'/hiera/path' => 'fullpath'})
        expect(@context).to receive(:cached_value).with('/hiera/path').and_return('fullpath')
        expect(@context).to receive(:cache_has_key).with('/hiera/path').and_return(true)
        expect(function.lookup_key('path', options, @context)).to eq('fullpath')
      end

      it "find string using another region" do
        options['region'] = 'us-east-2'
        expect(@context).to receive(:interpolate).with('/region2').and_return('/region2')
        allow(@context).to receive(:cache).with({'region2' => 'ohio'})
        expect(@context).to receive(:cached_value).with('region2').and_return('ohio')
        expect(@context).to receive(:cache_has_key).with('region2').and_return(true)
        expect(function.lookup_key('region2', options, @context)).to eq('ohio')
      end
    end
  end
end
