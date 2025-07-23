require 'rubygems'

Gem::Specification.new do |spec|
  spec.name        = 'oracle-model-generator'
  spec.version     = '0.5.0'
  spec.author      = 'Daniel J. Berger'
  spec.license     = 'Apache-2.0'
  spec.email       = 'djberg96@gmail.com'
  spec.homepage    = 'http://www.github.com/djberg96/oracle-model-generator'
  spec.summary     = 'A Ruby interface for determining protocol information'
  spec.test_files  = Dir['spec/**/*.rb']
  spec.files       = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.cert_chain  = spec.cert_chain = ['certs/djberg96_pub.pem']

  spec.executables = "dmg"

  spec.add_dependency('ruby-oci8', '~> 2.2')
  spec.add_dependency('getopt', '~> 1.6')
  spec.add_development_dependency('rspec', '~> 3.12')

  spec.description = <<-EOF
    The oracle-model-generator library allows you to generate an ActiveRecord
    model from an existing Oracle table or view, as well as automatically
    generate a baseline test file for test-unit or minitest.
  EOF
end
