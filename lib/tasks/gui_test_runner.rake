# frozen_string_literal: true

require 'drb/drb'
require 'rake'
require 'gui_test_runner/test_suite'

namespace :gui_test_runner do
  desc 'Rerun all examples'
  task :rerun_all_examples do
    GUITestRunner::Tasks.rerun_all_examples
  end

  desc 'Rerun all failed examples'
  task :rerun_failed_examples do
    GUITestRunner::Tasks.rerun_failed_examples
  end

  desc 'Rerun specific example'
  task :rerun_example, :example_path do |_, args|
    GUITestRunner::Tasks.rerun_example(args[:example_path])
  end
end

module GUITestRunner
  module Tasks
    class << self
      TEST_SUITE = DRbObject.new_with_uri(GUITestRunner::TestSuiteServer::SERVER_URI)

      def rerun_all_examples
        Dir.chdir(Bundler.root)
        `bundle exec #{TEST_SUITE.run_command}`
      end

      def rerun_failed_examples
        examples = TEST_SUITE.failed_examples
        rerun_examples(examples) if examples.length > 0
      end

      def rerun_example(example_path)
        Dir.chdir(Bundler.root)
        `RERUN=1 bundle exec rspec #{example_path}`
      end

      def rerun_examples(examples)
        Dir.chdir(Bundler.root)
        examples_locations = examples.map { |example| example.absolute_location }
        examples.each { |example| example.process.remove_example(example.parameterized_spec_id) }
        `RERUN=1 bundle exec rspec #{examples_locations.join(' ')}`
      end
    end
  end
end
