require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rbconfig'
include Config

CLEAN.include("**/*.gem", "**/*.rbc", "**/*.log")

namespace 'gem' do
  desc 'Create the oracle-model-generator gem'
  task :create => :clean do
    spec = eval(IO.read('oracle-model-generator.gemspec'))
    Gem::Builder.new(spec).build
  end

  desc 'Install the oracle-model-generator gem'
  task :install => [:create] do
    file = Dir["oracle-model-generator*.gem"].last
    sh "gem install #{file}"
  end
end

Rake::TestTask.new do |t|
  t.warning = true
  t.verbose = true
end

task :default => :test
