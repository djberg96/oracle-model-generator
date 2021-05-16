require 'rake'
require 'rake/testtask'
require 'rake/clean'

CLEAN.include("**/*.gem", "**/*.rbc", "**/*.log", "**/*.lock")

namespace 'gem' do
  desc 'Create the oracle-model-generator gem'
  task :create => :clean do
    require 'rubygems/package'
    spec = Gem::Specification.load('oracle-model-generator.gemspec')
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec)
  end

  desc 'Install the oracle-model-generator gem'
  task :install => [:create] do
    file = Dir["oracle-model-generator*.gem"].last
    sh "gem install -l #{file}"
  end
end

Rake::TestTask.new do |t|
  t.warning = true
  t.verbose = true
end

task :default => :test
