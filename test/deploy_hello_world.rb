require_relative 'google/chefconf16'

deployer = Google::ChefConf16::AppengineDeploy.new(
  :app_id => 'google.com:graphite-playground',
  :service_id => 'default',
  :bucket_name => 'graphite-playground',
  :service_account_json =>
      File.expand_path("~/.config/gcloud/service_account.json"),
)
deployer.upload_files
deploy_info = deployer.create_new_version
deploy_info.wait_until_complete
puts "Created version #{deploy_info.version}."
puts "Staging application @ #{deploy_info.url}"
deployer.activate
puts "Production application @ #{deployer.production_url}"
deployer.cleanup
