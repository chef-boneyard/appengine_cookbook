require 'google/chefconf16'

deployer = Google::ChefConf16::AppengineDeploy.new(
  :app_id => 'google.com:graphite-playground',
  :service_id => 'default',
  :bucket_name => 'graphite-playground',
  :service_account_json =>
      File.expand_path('~/.config/gcloud/service_account.json'),
  :app_yaml => '../app/app.yaml'
)

puts "Deploying version #{deployer.version_id}."
deployer.upload_files
deployer.create_new_version
deployer.wait_until_complete
puts "Created version #{deployer.version_id}."
puts "Staging application @ #{deployer.staging_url}"
deployer.activate
puts "Production application @ #{deployer.production_url}"
deployer.cleanup
