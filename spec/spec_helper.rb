require 'dm-core/spec/setup'
require 'dm-core/spec/lib/adapter_helpers'

require 'dm-is-nested_set'
require 'dm-migrations'

Spec::Runner.configure do |config|
  config.extend(DataMapper::Spec::Adapters::Helpers)
end
