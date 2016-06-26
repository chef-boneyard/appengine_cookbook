$LOAD_PATH << File.expand_path('./libraries')

require 'chefspec'
require 'chefspec/berkshelf'

at_exit { ChefSpec::Coverage.report! }
