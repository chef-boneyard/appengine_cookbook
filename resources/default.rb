resource_name :appengine

property :app_id, String, :name_property => true
property :app_yaml, String
property :service_id, String
property :bucket_name, String
property :service_account_json, String
property :source, String

default_action :create

action :create do
  deployer = Google::ChefConf16::AppengineDeploy.new(
    :app_id => app_id,
    :app_yaml => app_yaml,
    :service_id => service_id,
    :bucket_name => bucket_name,
    :service_account_json => service_account_json
  )
  deployer.upload_files
  deployer.create_new_version
  deployer.wait_until_complete
  puts "Created version #{deployer.version_id}."
  puts "Staging application @ #{deployer.staging_url}"
  deployer.activate
  puts "Production application @ #{deployer.production_url}"
end

action :upload do
  deployer = Google::ChefConf16::AppengineDeploy.new(
    :app_id => app_id,
    :app_yaml => app_yaml,
    :service_id => service_id,
    :bucket_name => bucket_name,
    :service_account_json => service_account_json
  )
  deployer.upload_files
  puts "Created version #{deployer.version_id}."
end

action :delete do
  deployer = Google::ChefConf16::AppengineDeploy.new(
    :app_id => app_id,
    :app_yaml => app_yaml,
    :service_id => service_id,
    :bucket_name => bucket_name,
    :service_account_json => service_account_json
  )
  deployer.cleanup
end

action :activate do
  deployer = Google::ChefConf16::AppengineDeploy.new(
    :app_id => app_id,
    :app_yaml => app_yaml,
    :service_id => service_id,
    :bucket_name => bucket_name,
    :service_account_json => service_account_json
  )
  deployer.activate
  puts "Production application @ #{deployer.production_url}"
end

action :stage do
  deployer = Google::ChefConf16::AppengineDeploy.new(
    :app_id => app_id,
    :app_yaml => app_yaml,
    :service_id => service_id,
    :bucket_name => bucket_name,
    :service_account_json => service_account_json
  )
  deployer.upload_files
  deployer.create_new_version
  deployer.wait_until_complete
  puts "Created version #{deployer.version_id}."
  puts "Staging application @ #{deployer.staging_url}"
end
