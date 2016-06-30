# coding: utf-8
# Copyright 2016 Chef Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Location to clone the code from
default['appengine']['repository'] = 'https://github.com/jjasghar/appengine_hello_world'

# Location for the source repo to clone the repository
default['appengine']['source_location'] = '/tmp/hello_world'

# branch to clone the code from
default['appengine']['branch'] = 'master'

# demo of appengine
default['appengine']['demo'] = false
