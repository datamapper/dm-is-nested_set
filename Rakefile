require 'rubygems'
require 'rake'

begin
  gem 'jeweler', '~> 1.4'
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name        = 'dm-is-nested_set'
    gem.summary     = 'DataMapper plugin allowing the creation of nested sets from data models'
    gem.description = gem.summary
    gem.email       = 'sindre [a] identu [d] no'
    gem.homepage    = 'http://github.com/datamapper/%s' % gem.name
    gem.authors     = [ 'Sindre Aarsaether' ]

    gem.rubyforge_project = 'datamapper'

    gem.add_dependency 'dm-core',   '~> 1.0.1'
    gem.add_dependency 'dm-adjust', '~> 1.0.1'

    gem.add_development_dependency 'rspec', '~> 1.3'
  end

  Jeweler::GemcutterTasks.new

  FileList['tasks/**/*.rake'].each { |task| import task }
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end
