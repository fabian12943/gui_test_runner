# frozen_string_literal: true

require 'drb/drb'
require 'concurrent/hash'
require 'gui_test_runner/examples/example_factory'
require 'gui_test_runner/examples/examples'

module GUITestRunner
  class TestProcess
    include DRb::DRbUndumped

    attr_reader :pid, :status, :start_time
    attr_accessor :total_examples, :end_time

    def initialize(pid)
      @pid = pid
      @total_examples = 0
      @start_time = Time.now
      @end_time = nil
      @status = TestProcessStatus.new(self)
      @examples = DRbObject.new(Concurrent::Hash.new, nil)
    end

    def examples
      @examples.values
    end

    def example(spec_id)
      @examples[spec_id]
    end

    def add_or_update_example(example)
      example.process = self
      @examples[example.parameterized_spec_id] = DRbObject.new(example)
      status.update_for_new_example(example)
    end

    def remove_example(spec_id)
      example = example(spec_id)
      unless example.nil?
        status.update_for_deleted_example(example)
        @examples.delete(spec_id) { false }
      end
    end

    def run_time
      time_diff = start_time - (end_time || Time.now)
      Time.at(time_diff.to_i.abs).utc.strftime '%H:%M:%S'
    end

    class TestProcessStatus
      attr_reader :test_process, :total_running_examples, :total_passed_examples, :total_failed_examples,
                  :total_pending_examples
      attr_accessor :test_process_running

      def initialize(test_process)
        @test_process = test_process
        @test_process_running = true
        @total_running_examples = 0
        @total_passed_examples = 0
        @total_failed_examples = 0
        @total_pending_examples = 0
      end

      def total_finished_examples
        [total_passed_examples, total_failed_examples, total_pending_examples].sum
      end

      def total_unfinished_examples
        test_process.total_examples - total_finished_examples
      end

      def progress_in_percent
        total_finished_examples.to_f / test_process.total_examples
      end

      def test_execution_complete?
        test_process.total_examples.positive? && (test_process.total_examples == total_finished_examples)
      end

      def test_execution_stopped_early?
        !test_process_running && !test_execution_complete?
      end

      def update_for_new_example(example)
        status = example.status
        if status == :running
          @total_running_examples += 1
        elsif %i[passed failed pending].include?(status)
          @total_running_examples -= 1
          @total_passed_examples += 1 if status == :passed
          @total_failed_examples += 1 if status == :failed
          @total_pending_examples += 1 if status == :pending
        end
      end

      def update_for_deleted_example(example)
        status = example.status
        test_process.total_examples -= 1
        @total_passed_examples -= 1 if status == :passed
        @total_failed_examples -= 1 if status == :failed
        @total_pending_examples -= 1 if status == :pending
      end
    end
  end
end
