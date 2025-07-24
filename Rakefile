require 'rake'
require 'rake/clean'
require 'rspec/core/rake_task'

CLEAN.include("**/*.gem", "**/*.rbc", "**/*.log", "**/*.lock")

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ['--format', 'documentation', '--color']
end
  
desc 'Run RSpec tests'
task :rspec => :spec

namespace 'gem' do
  desc 'Create the database-model-generator gem'
  task :create => :clean do
    require 'rubygems/package'
    spec = Gem::Specification.load('database-model-generator.gemspec')
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec)
  end

  desc 'Install the database-model-generator gem'
  task :install => [:create] do
    file = Dir["database-model-generator*.gem"].last
    sh "gem install -l #{file}"
  end
end

# Set default task to run both test suites
task :default => [:spec]
