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

module Google
  module ChefConf16
    class AppengineDeploy < Chef::Resource
      @store_api = 'https://storage.googleapis.com'

      def initialize(args = {})
        require 'google/apis/appengine_v1beta5'
        require 'google/apis/storage_v1'

        # TODO(nelsona): Move this to a gem and not require '_relative'
        require_relative 'google_credential_helper'

        raise 'Missing :app_id' unless (@app_id = args[:app_id])
        raise 'Missing :serviceid' unless (@service_id = args[:service_id])
        raise 'Missing :bucket_name' unless (@bucket_name = args[:bucket_name])
        raise 'Missing :service_account_json' \
            unless (@service_account_json = args[:service_account_json])
        @bucket_uri = "#{@store_api}/#{@bucket_name}"
        @ver_id = Time.new.iso8601.to_s.delete('-').delete(':').delete('+').downcase
        @file_upload_path = "myapp/mymain-#{@ver_id}.py"
      end

      def version
        @ver_id
      end

      def url
        # TODO(nelsona): Implement this
        'TBD'
      end

      # Upload our program to a bucket, so deployment can fetch it
      def upload_files(source)
        storage = Google::CredentialHelper.new
                                          .for!(Google::Apis::StorageV1::AUTH_DEVSTORAGE_READ_WRITE)
                                          .from_service_account_json!(@service_account_json)
                                          .authorize Google::Apis::StorageV1::StorageService.new
        print "Uploading file to gs://#{@bucket_name}/#{@file_upload_path}..."
        upload(source, storage)
        puts ' done.'
      end

      def upload(source, storage)
        Dir.glob("#{source}/**/*").select do |e|
          next unless ::File.file? e
          storage.insert_object(
            @bucket_name,
            Google::Apis::StorageV1::Object.new(
              :id => @file_upload_path
            ),
            :name => @file_upload_path,
            :upload_source => ::File.open(e)
          )
        end
      end

      # Create a new version of the application
      def create_new_version(source)
        @app_engine =
          Google::CredentialHelper.new
                                  .for!(Google::Apis::AppengineV1beta5::AUTH_CLOUD_PLATFORM)
                                  .from_service_account_json!(@service_account_json)
                                  .authorize Google::Apis::AppengineV1beta5::AppengineService.new

        version_info = YAML.load(::File.read("#{source}/app.yaml"))
        version = Google::Apis::AppengineV1beta5::Version.new(
          :id => @ver_id,
          :name => "apps/#{@app_id}/services/#{@service_id}/versions/#{@ver_id}",
          :api_version => version_info['api_version'],
          :runtime => version_info['runtime'],
          :threadsafe => version_info['threadsafe'],
          :handlers => version_info['handlers'].map do |handler|
            Google::Apis::AppengineV1beta5::UrlMap.new(
              :url_regex => handler['url'],
              :script => Google::Apis::AppengineV1beta5::ScriptHandler.new(
                :script_path => handler['script']))
          end,
          :deployment => {
            :files => {
              'main.py' => Google::Apis::AppengineV1beta5::FileInfo.new(
                :source_url => "#{@bucket_uri}/#{@file_upload_path}")
            }
          }
        )

        print 'Requesting create new version for the application...'
        new_version = @app_engine.create_app_service_version(
          @app_id, @service_id, version)
        puts ' done.'
        operation_id = new_version.name.split('/').last
        operation_id
      end

      # Wait for an operation to complete
      def wait_for_operation(operation_id)
        print 'Waiting for deployment to complete...'
        until @app_engine.get_app_operation(@app_id, operation_id).done?
          print '.'
          sleep 1
        end
        puts ' done.'
      end

      # Activate App Engine application
      def activate
        #
        #

        # TODO(nelsona)
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
