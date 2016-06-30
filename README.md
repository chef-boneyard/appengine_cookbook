# appengine cookbook

[![Build Status](https://travis-ci.org/chef-partners/appengine-cookbook.svg?branch=master)](https://travis-ci.org/chef-partners/appengine-cookbook)

## Description

Manage deployment and configuration of a AppEngine application from Google.

## Requirements

- Ubuntu 14.04 +
- CentOS 7.2 +

## Usage

Add the `appengine` cookbook to your `run_list`, to make sure that the dependancies are there. After this we have a Custom Resource to create appengine resource.
For instance, the following will create `"formal-platform-134918"` with the following settings.

```ruby
  appengine "formal-platform-134918" do
    app_id "formal-platform-134918" # this line is optional
    app_yaml "#{node.default['appengine']['source_location']}/app.yaml"
    service_id 'default'
    bucket_name 'chef-conf16-appengine'
    service_account_json   ::File.expand_path("/tmp/gcloud/service_account.json")
    source node.default['appengine']['source_location']
    action :create # this is default, so optional, but you can do the other actions here
  end
```

**app_id**: the name of your application id from https://appengine.google.com/

**service_id**: unless you know what it is, you should set it to `default`

**bucket_name**: the storage location for your appengine resource

**service_account**: the service account json from [here]( https://console.cloud.google.com/iam-admin/serviceaccounts/project?project=<your project name>&authuser=1), you should add it to `files/default/service_account.json` in this cookbook

**source**: location for the source repo to clone the repository

**action**:
- `:create` creates the app, uploads the files from the repo, then activates the app, this is the default action
- `:upload`uploads the files from the repo
- `:delete` deletes the app
- `:activate` activates the app
- `:stage` creates the app, uploads the files from the repo

## Recipe

### default

Installs the prerequisites to interact with the Google Appengine, including packages, and the gems required.

## Testing

### ChefSpec

There is basic coverage for the default recipe.

### InSpec

TBD

### Test Kitchen

The included [.kitchen.yml](.kitchen.yml) runs the default master deployment in a generic fashion.

## License and Author

- Author:: JJ Asghar (<jj@chef.io>)
- Author:: Franklin Webber (<fwebber@chef.io>)
- Author:: Nelson Araujo (<nelsona@google.com>)

Copyright 2016 Chef Software, Inc.

Copyright 2016 Google, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
