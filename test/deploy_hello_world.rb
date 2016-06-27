require 'google/chefconf16'

#BEGIN {
#
#  require 'net/http'
#  
#  Net::HTTP.module_eval do
#    alias_method '__initialize__', 'initialize'
#    
#    def initialize(*args,&block)
#      __initialize__(*args, &block)
#    ensure
#      @debug_output = $stderr ### if ENV['HTTP_DEBUG']
#    end
#  end
#
#}

deployer = Google::ChefConf16::AppengineDeploy.new(
  :app_id => 'graphite-playground-public',
  :service_id => 'default',
  :bucket_name => 'graphite-playground-public-store',
  :service_account_json =>
      File.expand_path('~/.config/gcloud/service_account.json'),
  :app_yaml => '../app/app.yaml'
)

#deployer.test
#exit

puts "Deploying version #{deployer.version_id}."
deployer.upload_files
deployer.create_new_version
deployer.wait_until_complete
puts "Created version #{deployer.version_id}."
puts "Staging application @ #{deployer.staging_url}"
deployer.activate
puts "Production application @ #{deployer.production_url}"
deployer.cleanup
