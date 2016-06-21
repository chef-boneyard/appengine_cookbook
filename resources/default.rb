resource_name :appengine

property :app_id, String, :name_property => true
property :service_id, String
property :bucket_name, String
property :service_account_json, String
property :source, String

default_action :create

action :create do
  deployer = Google::ChefConf16::AppengineDeploy.new(
    :app_id => app_id,
    :service_id => service_id,
    :bucket_name => bucket_name,
    :service_account_json => service_account_json
  )
  deployer.upload_files(source)
  deploy_id = deployer.create_new_version(source)
  deployer.wait_for_operation deploy_id
  puts "Created version #{deployer.version}."
  puts "Staging application @ #{deployer.url}"
  deployer.activate
end

action :upload do
  deployer = Google::ChefConf16::AppengineDeploy.new(
    :app_id => app_id,
    :service_id => service_id,
    :bucket_name => bucket_name,
    :service_account_json => service_account_json
  )
  deployer.upload_files(source)
  puts "Created version #{deployer.version}."
end

action :delete do
  deployer = Google::ChefConf16::AppengineDeploy.new(
    :app_id => app_id,
    :service_id => service_id,
    :bucket_name => bucket_name,
    :service_account_json => service_account_json
  )
  deployer.cleanup
end

action :activate do
  deployer = Google::ChefConf16::AppengineDeploy.new(
    :app_id => app_id,
    :service_id => service_id,
    :bucket_name => bucket_name,
    :service_account_json => service_account_json
  )
  deployer.activate
end

action :stage do
end
