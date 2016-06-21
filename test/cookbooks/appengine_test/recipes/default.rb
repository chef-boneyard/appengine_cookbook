# appengine 'name' do
# app_id:
# service_id:
# bucket_name:
# service_account_json:
# source: # source location for the code that needs to be shipped
# actions: create # default, it does upload_files and wait, and active
# end

include_recipe 'appengine::default'
