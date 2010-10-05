require 'rubygems'

Gem::Specification.new do |gem|
  gem.name       = 'oracle-model-generator'
  gem.version    = '0.1.0'
  gem.author     = 'Daniel J. Berger'
  gem.license    = 'Artistic 2.0'
  gem.email      = 'djberg96@gmail.com'
  gem.homepage   = 'http://www.github.com/djberg96/oracle-model-generator'
  gem.summary    = 'A Ruby interface for determining protocol information'
  gem.test_file  = 'test/test_oracle_model_generator.rb'
  gem.files      = Dir['**/*'].reject{ |f| f.include?('git') }

  gem.rubyforge_project = 'N/A'
  gem.extra_rdoc_files  = %w[CHANGES README MANIFEST]

  gem.add_dependency('ruby-oci8')
  gem.add_dependency('getopt', '>= 1.4.0')
  gem.add_development_dependency('test-unit', '>= 2.1.1')

  gem.description = <<-EOF
    The oracle-model-generator library allows you to generate an ActiveRecord
    model from an existing Oracle table or view.
  EOF
end
