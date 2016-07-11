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
      attr_reader :production_url
      attr_reader :staging_url
      attr_reader :version_id

      def initialize(args = {})
        require 'chef'
        require 'google/apis/appengine_v1beta5'
        require 'google/apis/storage_v1'
        require_relative 'credential_helper'

        store_api = 'https://storage.googleapis.com'

        raise 'Missing :app_id' if (@app_id = args[:app_id]).nil? || @app_id.empty?
        raise 'Missing :service_id' if (@service_id = args[:service_id]).nil? || @service_id.empty?
        raise 'Missing :bucket_name' \
            if (@bucket_name = args[:bucket_name]).nil? || @bucket_name.empty?
        raise 'Missing :service_account_json' \
            if (@service_account_json = args[:service_account_json]).nil? \
                || @service_account_json.empty?
        raise 'Missing :app_yaml' if (@app_yaml = args[:app_yaml]).nil? || @app_yaml.empty?

        @bucket_uri = "#{store_api}/#{@bucket_name}"
        @bucket_path = args[:bucket_path].nil? ? @app_id : args[:bucket_path]

        @version_info = YAML.load(::File.read(@app_yaml))

        @version_id = args[:version_id] if args.key?(:version_id)
        @version_id ||= Time.new.iso8601.to_s.delete('-').delete(':').delete('+').downcase

        @cleaned_app_id = @app_id.gsub(/.*:/, '')
        appengine_domain = @app_id.start_with?('google.com:') ? 'googleplex' : 'appspot'
        @production_url = "https://#{@cleaned_app_id}.#{appengine_domain}.com/"
        @staging_url = "https://#{@version_id}-dot-#{@cleaned_app_id}.#{appengine_domain}.com/"

        @uploaded_files = {}

        @app_engine =
          Google::CredentialHelper.new
                                  .for!(Google::Apis::AppengineV1beta5::AUTH_CLOUD_PLATFORM)
                                  .from_service_account_json!(@service_account_json)
                                  .authorize Google::Apis::AppengineV1beta5::AppengineService.new
      end

      # Upload our program to a bucket, so deployment can fetch it
      #
      # Note: this version does not support mapping using regular expressions.
      def upload_files
        storage = Google::CredentialHelper.new
                                          .for!(Google::Apis::StorageV1::AUTH_DEVSTORAGE_READ_WRITE)
                                          .from_service_account_json!(@service_account_json)
                                          .authorize Google::Apis::StorageV1::StorageService.new
        app_yaml_dir = ::File.expand_path(::File.dirname(@app_yaml))

        @version_info['handlers'].each do |handler|
          if handler.key?('static_files')
            file_glob = "#{app_yaml_dir}/#{handler['upload']}"
          elsif handler.key?('static_dir')
            # TODO(nelsona): Add support to directories
            raise 'Uploading directories is not supported'
          elsif handler.key?('script')
            script = handler['script']
            file_glob = "#{app_yaml_dir}/#{::File.basename(script, ::File.extname(script))}.*"
          else
            raise 'Unknown handler type'
          end

          Dir.glob(file_glob).select do |e|
            file_name = Pathname.new(e).relative_path_from Pathname.new(app_yaml_dir)
            file_bucket = "#{@bucket_path}/#{@version_id}/#{file_name}"
            STDERR.print "Uploading file to gs://#{@bucket_name}/#{file_bucket}..."
            storage.insert_object(
              @bucket_name,
              Google::Apis::StorageV1::Object.new(
                :id => file_bucket
              ),
              :name => file_bucket,
              :upload_source => ::File.open(e)
            )
            @uploaded_files[handler] = {
              :filename => file_name,
              :bucket => file_bucket
            }
            STDERR.puts ' done.'
          end
        end
      end

      # Create a new version of the application
      def create_new_version
        version = Google::Apis::AppengineV1beta5::Version.new(
          :id => @version_id,
          :name => "apps/#{@app_id}/services/#{@service_id}/versions/#{@version_id}",
          :api_version => @version_info['api_version'],
          :runtime => @version_info['runtime'],
          :threadsafe => @version_info['threadsafe'],
          :handlers => @version_info['handlers'].map do |handler|
            if handler.key?('static_files')
              Google::Apis::AppengineV1beta5::UrlMap.new(
                :url_regex => handler['url'],
                :static_files => Google::Apis::AppengineV1beta5::StaticFilesHandler.new(
                  :path => handler['static_files'],
                  :upload_path_regex => "#{@bucket_uri}/#{@uploaded_files[handler][:bucket]}"))
            elsif handler.key?('static_dir')
              # TODO(nelsona): Add support to directories
              raise 'Uploading directories is not supported'
            elsif handler.key?('script')
              Google::Apis::AppengineV1beta5::UrlMap.new(
                :url_regex => handler['url'],
                :script => Google::Apis::AppengineV1beta5::ScriptHandler.new(
                  :script_path => handler['script']))
            else
              raise 'Unknown handler tye'
            end
          end
          .compact,
          :deployment => {
            :files => Hash[*@uploaded_files.map do |_, path|
              [::File.basename(path[:filename]), Google::Apis::AppengineV1beta5::FileInfo.new(
                :source_url => "#{@bucket_uri}/#{path[:bucket]}")]
            end
            .flatten]
          }
        )

        STDERR.print 'Requesting create new version for the application...'
        new_version = @app_engine.create_app_service_version(
          @app_id, @service_id, version)
        STDERR.puts ' done.'

        @operation_id = new_version.name.split('/').last
      end

      # Wait for an operation to complete
      def wait_until_complete
        STDERR.print 'Waiting for deployment to complete...'
        until (operation = @app_engine.get_app_operation(@app_id, @operation_id)).done?
          STDERR.print '.'
          sleep 1
        end
        STDERR.puts ' done.'
        raise "Failed to deploy application: #{operation.error.inspect}" unless operation.error.nil?
      end

      # Activate App Engine application
      #
      # Note: In a real production application you may want a smooth traffic transition. This
      # application does a one shot transition only.
      def activate
        STDERR.print "Activating version #{@version_id}..."
        service = @app_engine.get_app_service(@app_id, @service_id)
        service.split.allocations.clear
        service.split.allocations[@version_id] = 1
        @app_engine.patch_app_service(@app_id, @service_id, service, :mask => 'split')
        STDERR.puts ' done.'
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
