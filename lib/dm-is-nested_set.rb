require 'pathname'
require 'rubygems'

gem 'dm-core', '0.10.0'
require 'dm-core'
require 'dm-core/core_ext/symbol'

#gem 'dm-adjust', '0.10.0'
require 'dm-adjust'

require Pathname(__FILE__).dirname.expand_path / 'dm-is-nested_set' / 'is' / 'nested_set'
