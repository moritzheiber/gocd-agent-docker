require 'spec_helper'

# rubocop:disable Metrics/BlockLength, RSpec/DescribeClass
describe 'GoCD agent container', :extend_helpers do
  set :docker_container, 'gocd-agent'

  # rubocop:disable Rspec/BeforeAfterAll
  before(:all) do
    compose.up('gocd-agent', detached: true)
  end

  after(:all) do
    compose.kill
    compose.rm(force: true)
  end
  # rubocop:enable Rspec/BeforeAfterAll

  describe 'the operating system' do
    it 'is alpine' do
      expect(os_version).to include('alpine')
    end
  end

  describe group('gocd') do
    it { should exist }
  end

  describe user('gocd') do
    it { should exist }
    it { should have_login_shell '/bin/sh' }
    it { should have_home_directory '/home/gocd' }
    it { should belong_to_primary_group 'gocd' }
  end

  %w[
    /gocd/config
    /gocd/runtime
    /gocd/runtime/config
  ].each do |d|
    describe file(d) do
      it { should be_directory }
      it { should be_mode 755 }
      it { should be_owned_by 'gocd' }
      it { should be_grouped_into 'gocd' }
    end
  end

  %w[
    curl
    unzip
  ].each do |p|
    describe package(p) do
      it { should_not be_installed }
    end
  end

  %w[
    terraform
    bash
    git
    docker
    ruby-dev
    ruby
    ruby-io-console
    ruby-etc
    jq
    tar
    build-base
    zlib-dev
    libffi-dev
    ca-certificates
  ].each do |p|
    describe package(p) do
      it { should be_installed }
    end
  end

  %w[
    /tmp/gocd.zip
    /tmp/extracted
  ].each do |file_absent|
    describe file(file_absent) do
      it { should_not exist }
    end
  end

  %w[
    /gocd/config/agent-launcher-logback.xml
    /gocd/config/agent-bootstrapper-logback.xml
    /gocd/runtime/config/autoregister.properties
  ].each do |file_present|
    describe file(file_present) do
      it { should be_file }
      it { should be_readable }
    end
  end

  describe file('/gocd/runtime/config/autoregister.properties') do
    its(:content) { should match(/agent\.auto\.register\.key=test/) }
    its(:content) { should match(/agent\.auto\.register\.resources=main/) }
  end

  [8152].each do |p|
    describe "port #{p}" do
      it 'is listening with tcp' do
        wait_for(port(p)).to be_listening.with('tcp')
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength, RSpec/DescribeClass
