# Copyright 2016 Google Inc.
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

# Public: Authorizes access to Google API objects.
#
# Examples
#
#   * Uses user credential stored in ~/.config/gcloud
#
#     api = Google::CredentialHelper.new
#         .for!('https://www.googleapis.com/auth/compute.readonly')
#         .from_user_credential!
#         .authorize Google::Apis::ComputeV1::ComputeService.new
#
#   * Uses service account specified by the :file argument (in JSON format)
#
#     api = Google::CredentialHelper.new
#         .for!('https://www.googleapis.com/auth/compute.readonly')
#         .from_service_account_json!(
#             File.join(File.expand_path('~'), "my_account.json"))
#         .authorize Google::Apis::ComputeV1::ComputeService.new
#
# TODO(nelsona): Add support gcloud's beta "app default credential"

module Google
  class CredentialHelper
    def initialize
      require 'google/api_client/client_secrets'
      require 'googleauth'
      require 'json'
      @scopes = []
    end

    def authorize(obj)
      raise ArgumentError, 'A from_* method needs to be called before' \
        unless @authorization
      obj.authorization = @authorization
      obj
    end

    def for!(*scopes)
      @scopes = scopes
      self
    end

    def from_user_credential!
      file = File.join(File.expand_path('~'), '.config', 'gcloud', 'credentials')
      creds = JSON.parse(File.read(file))

      cred = nil
      creds['data'].each do |entry|
        if entry['credential']['_class'] == 'OAuth2Credentials'
          cred = entry['credential']
          break
        end
      end

      raise "Credential not found in #{file}" unless cred

      hash = {
        'installed' => {
          'client_id' => cred['client_id'],
          'client_secret' => cred['client_secret'],
          'refresh_token' => cred['refresh_token']
        }
      }

      @authorization = Google::APIClient::ClientSecrets.new(hash)
                                                       .to_authorization
      self
    end

    def from_service_account_json!(service_account_file)
      raise 'Missing argument for scopes' if @scopes.empty?

      @authorization = Google::Auth::ServiceAccountCredentials.make_creds(:json_key_io => File.open(service_account_file),
                                                                          :scope => @scopes)
      self
    end

    def from_application_default_credentials!
      raise NotImplementedError, ':application_default_credentials'
    end
  end
end
