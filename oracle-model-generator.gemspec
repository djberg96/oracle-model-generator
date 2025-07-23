require 'rubygems'

Gem::Specification.new do |spec|
  spec.name        = 'oracle-model-generator'
  spec.version     = '0.6.0'
  spec.author      = 'Daniel J. Berger'
  spec.license     = 'Apache-2.0'
  spec.email       = 'djberg96@gmail.com'
  spec.homepage    = 'http://www.github.com/djberg96/oracle-model-generator'
  spec.summary     = 'A Ruby library for generating ActiveRecord models from Oracle and SQL Server databases'
  spec.test_files  = Dir['spec/**/*.rb']
  spec.files       = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.cert_chain  = spec.cert_chain = ['certs/djberg96_pub.pem']

  spec.executables = "dmg"

  # Database connections (optional - loaded dynamically)
  spec.add_dependency('ruby-oci8', '~> 2.2')
  spec.add_dependency('tiny_tds', '~> 2.1')
  spec.add_dependency('getopt', '~> 1.6')

  # Development dependencies
  spec.add_development_dependency('rspec', '~> 3.12')
  spec.add_development_dependency('rake', '~> 13.0')

  spec.description = <<-EOF
    The oracle-model-generator library allows you to generate ActiveRecord
    models from existing Oracle and SQL Server tables or views. Features include:

    * Automatic polymorphic association detection
    * Smart enum generation from database CHECK constraints
    * Support for both Oracle (via ruby-oci8) and SQL Server (via tiny_tds)
    * Intelligent foreign key and index recommendations
    * Baseline test file generation for RSpec

    The generated models include proper Rails associations, validations, and
    enum definitions based on your database schema.
  EOF
end
