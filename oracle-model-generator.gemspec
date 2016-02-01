require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'oracle-model-generator'
  spec.version    = '0.4.1'
  spec.author     = 'Daniel J. Berger'
  spec.license    = 'Artistic 2.0'
  spec.email      = 'djberg96@gmail.com'
  spec.homepage   = 'http://www.github.com/djberg96/oracle-model-generator'
  spec.summary    = 'A Ruby interface for determining protocol information'
  spec.test_file  = 'test/test_oracle_model_generator.rb'
  spec.files      = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.cert_chain = spec.cert_chain = ['certs/djberg96_pub.pem']

  spec.executables = "omg"
  spec.extra_rdoc_files = %w[CHANGES README MANIFEST]

  spec.add_dependency('ruby-oci8')
  spec.add_dependency('getopt')
  spec.add_development_dependency('test-unit')

  spec.description = <<-EOF
    The oracle-model-generator library allows you to generate an ActiveRecord
    model from an existing Oracle table or view, as well as automatically
    generate a baseline test file for test-unit or minitest.
  EOF
end
