# coding: utf-8
# Copyright 2016 Google Inc.
# Copyright 2016 Chef Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef'
require 'google/apis/appengine_v1beta5'
require 'google/apis/storage_v1'
require 'google/credential_helper'

module Google
  module ChefConf16
    class AppengineDeploy < Chef::Resource
      attr_reader :production_url
      attr_reader :staging_url
      attr_reader :version_id

      def initialize(args = {})
        store_api = 'https://storage.googleapis.com'

        raise 'Missing :app_id' if (@app_id = args[:app_id]).nil? || @app_id.empty?
        raise 'Missing :serviceid' if (@service_id = args[:service_id]).nil? || @service_id.empty?
        raise 'Missing :bucket_name' \
            if (@bucket_name = args[:bucket_name]).nil? || @bucket_name.empty?
        raise 'Missing :service_account_json' \
            if (@service_account_json = args[:service_account_json]).nil? \
                || @service_account_json.empty?
        raise 'Missing :app_yaml' if (@app_yaml = args[:app_yaml]).nil? || @app_yaml.empty?
        @bucket_uri = "#{store_api}/#{@bucket_name}"
        @bucket_path = args[:bucket_path].nil? ? @app_id : args[:bucket_path]
        @version_id = Time.new.iso8601.to_s.delete('-').delete(':').delete('+').downcase
        @version_info = YAML.load(::File.read(@app_yaml))
        @uploaded_files = {}
      end

      # Upload our program to a bucket, so deployment can fetch it
      def upload_files
        storage = Google::CredentialHelper.new
                                          .for!(Google::Apis::StorageV1::AUTH_DEVSTORAGE_READ_WRITE)
                                          .from_service_account_json!(@service_account_json)
                                          .authorize Google::Apis::StorageV1::StorageService.new
        Dir.glob("#{::File.dirname(@app_yaml)}/**/*").select do |e|
          next unless ::File.file? e
          file_name = ::File.basename(e)
          file_bucket = "#{@bucket_path}/#{@version_id}/#{file_name}"
          print "Uploading file to gs://#{@bucket_name}/#{file_bucket}..."
          storage.insert_object(
            @bucket_name,
            Google::Apis::StorageV1::Object.new(
              :id => file_bucket
            ),
            :name => file_bucket,
            :upload_source => ::File.open(e)
          )
          @uploaded_files[file_name] = file_bucket if file_name != 'app.yaml'
          puts ' done.'
        end
      end

      # Create a new version of the application
      def create_new_version
        @app_engine =
          Google::CredentialHelper.new
                                  .for!(Google::Apis::AppengineV1beta5::AUTH_CLOUD_PLATFORM)
                                  .from_service_account_json!(@service_account_json)
                                  .authorize Google::Apis::AppengineV1beta5::AppengineService.new

        version = Google::Apis::AppengineV1beta5::Version.new(
          :id => @version_id,
          :name => "apps/#{@app_id}/services/#{@service_id}/versions/#{@version_id}",
          :api_version => @version_info['api_version'],
          :runtime => @version_info['runtime'],
          :threadsafe => @version_info['threadsafe'],
          :handlers => @version_info['handlers'].map do |handler|
            Google::Apis::AppengineV1beta5::UrlMap.new(
              :url_regex => handler['url'],
              :script => Google::Apis::AppengineV1beta5::ScriptHandler.new(
                :script_path => handler['script']))
          end,
          :deployment => {
            :files => Hash[*@uploaded_files.map do |name, path|
              [name, Google::Apis::AppengineV1beta5::FileInfo.new(
                :source_url => "#{@bucket_uri}/#{path}")]
            end
            .flatten]
          }
        )

        print 'Requesting create new version for the application...'
        new_version = @app_engine.create_app_service_version(
          @app_id, @service_id, version)
        puts ' done.'

        @operation_id = new_version.name.split('/').last
      end

      # Wait for an operation to complete
      def wait_until_complete
        print 'Waiting for deployment to complete...'
        until @app_engine.get_app_operation(@app_id, @operation_id).done?
          print '.'
          sleep 1
        end
        puts ' done.'
        @staging_url = "https://#{@version_id}-dot-#{@app_id.gsub(/.*:/, '')}.googleplex.com/"
      end

      # Activate App Engine application
      def activate
        @production_url = "https://#{@app_id.gsub(/.*:/, '')}.googleplex.com/"
      end

      def cleanup
        #
        # File is already deployed to App Engine. Delete temporary file
        #

        # TODO(nelsona)
      end
    end
  end
end
