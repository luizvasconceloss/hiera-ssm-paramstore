# frozen_string_literal: true

require 'spec_helper'

describe 'hiera_ssm_paramstore' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      context 'with environment vagrant' do
        let(:environment) { 'vagrant' }

        it { is_expected.to contain_package('aws-sdk-ssm').with_provider('puppet_gem') }
      end
      context 'with other environment' do
        it { is_expected.to contain_package('aws-sdk-ssm').with_provider('puppetserver_gem') }
      end
    end
  end
end
