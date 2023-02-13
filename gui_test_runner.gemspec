lib = File.expand_path('lib', __dir__.to_s)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gui_test_runner/version'

Gem::Specification.new do |spec|
  spec.name = 'gui_test_runner'
  spec.version = GUITestRunner::VERSION
  spec.required_ruby_version = '>= 2.6'
  spec.authors = ['Fabian Schwarz']
  spec.email = ['fabian.schwarz@makandra.de']

  spec.summary = 'Graphical user interface for RSpec test suites'
  spec.description = <<-TEXT
    This gem provides a graphical user interface through which the current progress of a 
    RSpec test suite can be monitored and individual tests can be restarted. For failed 
    tests the corresponding error messages get displayed.
  TEXT
  spec.homepage = 'https://github.com/fabian12943/gui_test_runner'
  spec.license = 'MIT'

  spec.files = `git ls-files | grep -E '^(bin|lib|web|tasks)'`.split("\n")
  spec.executables = ['gui_test_runner']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'drb'
  spec.add_dependency 'haml'
  spec.add_dependency 'httparty'
  spec.add_dependency 'makandra-rubocop'
  spec.add_dependency 'parallel_tests'
  spec.add_dependency 'rack'
  spec.add_dependency 'rake'
  spec.add_dependency 'rspec', '~> 3.11'
  spec.add_dependency 'rspec-rails'
  spec.add_dependency 'rubocop'
  spec.add_dependency 'sinatra', '~> 3.0'
  spec.add_dependency 'sinatra-contrib'
  spec.add_dependency 'thin'
end
