require 'rspec/core'
require 'rspec/core/formatters/base_formatter'
require 'drb/drb'
require 'parallel_tests'
require 'gui_test_runner/examples/examples'
require 'gui_test_runner/examples/rspec_adapters'
require 'gui_test_runner/examples/example_factory'
require 'gui_test_runner/test_suite'
require 'gui_test_runner/web/report_updater'

module GUITestRunner
  class Formatter < RSpec::Core::Formatters::BaseFormatter
    RSpec::Core::Formatters.register self,
                                     :start,
                                     :example_started,
                                     :example_passed,
                                     :example_failed,
                                     :example_pending,
                                     :stop

    attr_reader :test_suite, :process

    def initialize
      begin
        @test_suite = DRbObject.new_with_uri(TestSuiteServer::SERVER_URI)
        if ParallelTests.first_process?
          test_suite.running_parallel = running_parallel?
          test_suite.clear unless rerun?
          test_suite.start_time = Time.now
          ReportUpdater.start_of_test_suite(rerun: rerun?)
          test_suite.run_command = run_command unless rerun?
        else
          sleep(0.5)
        end

        @process = test_suite.process(Process.pid)
      rescue DRb::DRbConnError
        @test_suite = nil
      end
    end

    def start(notification)
      return unless test_suite

      process.total_examples = notification.count
    end

    def example_started(notification)
      return unless test_suite

      example = ExampleFactory.from_rspec_notification(notification)
      process.add_or_update_example(example)
      rerun? ? ReportUpdater.update_example(example) : ReportUpdater.new_example(example)
    end

    def example_passed(notification)
      return unless test_suite

      example = ExampleFactory.from_rspec_notification(notification)
      process.add_or_update_example(example)
      ReportUpdater.update_example(example)
    end

    def example_failed(notification)
      return unless test_suite

      example = ExampleFactory.from_rspec_notification(notification)
      process.add_or_update_example(example)
      ReportUpdater.update_example(example)
    end

    def example_pending(notification)
      return unless test_suite

      example = ExampleFactory.from_rspec_notification(notification)
      process.add_or_update_example(example)
      ReportUpdater.update_example(example)
    end

    def stop(_notification)
      return unless test_suite

      process.status.test_process_running = false
      process.end_time = Time.now
      ReportUpdater.end_of_test_suite if test_suite.status.test_execution_complete?
    end

    def rerun?
      ENV['RERUN'] == '1'
    end

    def running_parallel?
      ENV['TEST_ENV_NUMBER']
    end

    def run_command
      process_id = running_parallel? ? Process.ppid : Process.pid
      `ps -p #{process_id} -o args --no-headers`
    end
  end
end


