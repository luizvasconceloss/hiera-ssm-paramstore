require 'spec_helper'

describe 'hiera_ssm_paramstore' do
  let(:context) { Puppet::Pops::Lookup::Context.new('m', 'm') }

  before(:each) do
    allow(context).to receive(:cache_has_key)
    allow(context).to receive(:explain)
    allow(context).to receive(:interpolate)
    allow(context).to receive(:cache)
    allow(context).to receive(:not_found)
  end

  describe 'lookup_key' do
    context 'Should run fetching single key' do
      let(:options) do
        {
          'uri' => '/',
          'region' => 'us-east-1',
          'get_all' => false,
        }
      end

      it 'find string' do
        expect(context).to receive(:interpolate).with('/plain').and_return('/plain')
        is_expected.to run.with_params('plain', options, context).and_return('value_plain')
      end

      it 'find secure string' do
        expect(context).to receive(:interpolate).with('/encrypted').and_return('/encrypted')
        is_expected.to run.with_params('encrypted', options, context).and_return('value_encrypted')
      end

      it 'not find value' do
        expect(context).to receive(:interpolate).with('/nonexists').and_return('/nonexists')
        expect(context).to receive(:not_found)
        is_expected.to run.with_params('nonexists', options, context).and_return(nil)
      end

      it 'find string using another region' do
        options['region'] = 'us-east-2'
        expect(context).to receive(:interpolate).with('/region2').and_return('/region2')
        is_expected.to run.with_params('region2', options, context).and_return('ohio')
      end

      it 'find translate string' do
        expect(context).to receive(:interpolate).with('/plain/translate').and_return('/plain/translate')
        is_expected.to run.with_params('plain::translate', options, context).and_return('parameter_value')
      end
    end

    context 'Should run without a hiera context' do
      let(:options) do
        {
          'uri' => '/',
          'region' => 'us-east-1',
          'get_all' => false,
        }
      end

      it 'find string' do
        is_expected.to run.with_params('plain', options).and_return('value_plain')
      end

      it 'find secure string' do
        is_expected.to run.with_params('encrypted', options).and_return('value_encrypted')
      end

      it 'not find value' do
        is_expected.to run.with_params('nonexists', options).and_return(nil)
      end

      it 'find string using another region' do
        options['region'] = 'us-east-2'
        is_expected.to run.with_params('region2', options).and_return('ohio')
      end

      it 'find translate string' do
        is_expected.to run.with_params('plain::translate', options).and_return('parameter_value')
      end
    end

    context 'Should run fetching all keys' do
      let(:options) do
        {
          'uri' => '/',
          'region' => 'us-east-1',
          'get_all' => true,
          'recursive' => true,
        }
      end

      it 'find string' do
        expect(context).to receive(:interpolate).with('/plain').and_return('/plain')
        allow(context).to receive(:cache).with('plain' => 'value_plain')
        expect(context).to receive(:cached_value).with('plain').and_return('value_plain')
        expect(context).to receive(:cache_has_key).with('plain').and_return(true)
        is_expected.to run.with_params('plain', options, context).and_return('value_plain')
      end

      it 'find secure string' do
        expect(context).to receive(:interpolate).with('/encrypted').and_return('/encrypted')
        allow(context).to receive(:cache).with('encrypted' => 'value_encrypted')
        expect(context).to receive(:cached_value).with('encrypted').and_return('value_encrypted')
        expect(context).to receive(:cache_has_key).with('encrypted').and_return(true)
        is_expected.to run.with_params('encrypted', options, context).and_return('value_encrypted')
      end

      it 'not find value' do
        expect(context).to receive(:interpolate).with('/nonexists').and_return('/nonexists')
        expect(context).to receive(:cache_has_key).with('nonexists').and_return(false)
        expect(context).to receive(:not_found)
        is_expected.to run.with_params('nonexists', options, context).and_return(nil)
      end

      it 'find string full path' do
        options['uri'] = '/hiera/'
        expect(context).to receive(:interpolate).with('/hiera/path').and_return('/hiera/path')
        allow(context).to receive(:cache).with('/hiera/path' => 'fullpath')
        expect(context).to receive(:cached_value).with('/hiera/path').and_return('fullpath')
        expect(context).to receive(:cache_has_key).with('/hiera/path').and_return(true)
        is_expected.to run.with_params('path', options, context).and_return('fullpath')
      end

      it 'find string using another region' do
        options['region'] = 'us-east-2'
        expect(context).to receive(:interpolate).with('/region2').and_return('/region2')
        allow(context).to receive(:cache).with('region2' => 'ohio')
        expect(context).to receive(:cached_value).with('region2').and_return('ohio')
        expect(context).to receive(:cache_has_key).with('region2').and_return(true)
        is_expected.to run.with_params('region2', options, context).and_return('ohio')
      end
    end
  end
end
