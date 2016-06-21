#
# Cookbook Name:: appengine
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'appengine::default' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs a chef_gem googleauth' do
      expect(chef_run).to install_chef_gem('googleauth')
    end

    it 'installs a chef_gem google-api-client' do
      expect(chef_run).to install_chef_gem('google-api-client')
    end

    it 'installs a chef_gem json' do
      expect(chef_run).to install_chef_gem('json')
    end

    it 'installs a package git' do
      expect(chef_run).to install_package('git')
    end

    it 'creates a directory /tmp/gcloud' do
      expect(chef_run).to create_directory('/tmp/gcloud')
    end

    it 'syncs a git /tmp/hello_world' do
      expect(chef_run).to sync_git('/tmp/hello_world')
    end

    it 'creates a cookbook_file /tmp/gcloud/service_account.json' do
      expect(chef_run).to create_cookbook_file('/tmp/gcloud/service_account.json')
    end
  end
end
