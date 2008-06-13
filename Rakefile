require 'rubygems'
require 'spec'
require 'rake/clean'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
require 'pathname'

CLEAN.include '{log,pkg}/'

spec = Gem::Specification.new do |s|
  s.name             = 'dm-is-nested_set'
  s.version          = '0.9.2'
  s.platform         = Gem::Platform::RUBY
  s.has_rdoc         = true
  s.extra_rdoc_files = %w[ README LICENSE TODO ]
  s.summary          = 'DataMapper plugin allowing the creation of nested sets from data models'
  s.description      = s.summary
  s.author           = 'Sindre Aarsaether'
  s.email            = 'sindre@identu.no'
  s.homepage         = 'http://github.com/sam/dm-more/tree/master/dm-is-nested_set'
  s.require_path     = 'lib'
  s.files            = FileList[ '{lib,spec}/**/*.rb', 'spec/spec.opts', 'Rakefile', *s.extra_rdoc_files ]
  s.add_dependency('dm-core', "=#{s.version}")
end

task :default => [ :spec ]

WIN32 = (RUBY_PLATFORM =~ /win32|mingw|cygwin/) rescue nil
SUDO  = WIN32 ? '' : ('sudo' unless ENV['SUDOLESS'])

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install #{spec.name} #{spec.version} (default ruby)"
task :install => [ :package ] do
  sh "#{SUDO} gem install --local pkg/#{spec.name}-#{spec.version} --no-update-sources", :verbose => false
end

desc "Uninstall #{spec.name} #{spec.version} (default ruby)"
task :uninstall => [ :clobber ] do
  sh "#{SUDO} gem uninstall #{spec.name} -v#{spec.version} -I -x", :verbose => false
end

namespace :jruby do
  desc "Install #{spec.name} #{spec.version} with JRuby"
  task :install => [ :package ] do
    sh %{#{SUDO} jruby -S gem install --local pkg/#{spec.name}-#{spec.version} --no-update-sources}, :verbose => false
  end
end

desc 'Run specifications'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts << '--options' << 'spec/spec.opts' if File.exists?('spec/spec.opts')
  t.spec_files = Pathname.glob(Pathname.new(__FILE__).dirname + 'spec/**/*_spec.rb')

  begin
    t.rcov = ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true
    t.rcov_opts << '--exclude' << 'spec'
    t.rcov_opts << '--text-summary'
    t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
  rescue Exception
    # rcov not installed
  end
end
