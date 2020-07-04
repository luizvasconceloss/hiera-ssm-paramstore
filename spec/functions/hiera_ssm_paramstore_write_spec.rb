require 'spec_helper'

describe 'hiera_ssm_paramstore_write' do
  describe 'write_key' do
    context 'Should run without a hiera context' do
      let(:options) do
        {
          'uri' => '/',
          'region' => 'us-east-1',
          'get_all' => false,
          'put' => { overwrite: true, tags: nil },
        }
      end

      it 'write string' do
        is_expected.to run.with_params('write/plain', 'write:value_plain', options).and_return('write:value_plain')
      end

      it 'write secure string' do
        options['put'] = { type: 'SecureString', overwrite: true, tags: nil }
        is_expected.to run.with_params('write/encrypted', 'write:value_encrypted', options).and_return('write:value_encrypted')
      end

      it 'write same key' do
        options['put'] = { overwrite: false }
        is_expected.to run.with_params('write/plain', 'write:value_plain', options).and_raise_error(Puppet::DataBinding::LookupError)
      end

      it 'write string using another region' do
        options['region'] = 'us-east-2'
        is_expected.to run.with_params('write/region2', 'write:ohio', options).and_return('write:ohio')
      end

      it 'write translate string' do
        is_expected.to run.with_params('write::plain::translate', 'write:parameter_value', options).and_return('write:parameter_value')
      end
    end
  end
end
