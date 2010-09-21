require 'rake'
require 'rake/testtask'
require 'rbconfig'
include Config

namespace 'gem' do
  desc 'Remove any old gem files'
  task :clean do
    Dir['*.gem'].each{ |f| File.delete(f) }
  end

  desc 'Create the oracle-model-generator gem'
  task :create => :clean do
    spec = eval(IO.read('oracle-model-generator.gemspec'))
    if Config::CONFIG['host_os'] =~ /linux/i
      spec.require_path = 'lib/linux'
      spec.platform = Gem::Platform::CURRENT
    end
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
