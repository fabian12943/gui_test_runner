# frozen_string_literal: true

require 'concurrent/hash'
require 'drb/timeridconv'
require 'singleton'
require 'gui_test_runner/test_process'

module GUITestRunner
  class TestSuite
    attr_reader :status
    attr_accessor :start_time, :running_parallel, :argv, :run_command

    def initialize
      @processes = Concurrent::Hash.new
      @status = TestSuiteStatus.new(self)
      @start_time = nil
      @running_parallel = nil
      @run_command = nil
    end

    def process(pid)
      @processes[pid] = TestProcess.new(pid) unless @processes.key?(pid)
      @processes[pid]
    end

    def processes
      @processes.values
    end

    def all_examples
      return [] if processes.empty?

      processes.collect(&:examples).flatten
    end

    def example(spec_id)
      return nil if processes.empty?

      processes.each do |process|
        return process.example(spec_id) unless process.example(spec_id).nil?
      end
      nil
    end

    def examples(spec_ids)
      return [] if processes.empty?

      examples = []
      spec_ids.each do |spec_id|
        examples << example(spec_id) unless example(spec_id).nil?
      end
      examples
    end

    def example_types
      all_examples.collect(&:type).uniq.sort
    end

    def remove_example(spec_id)
      return false if processes.empty?

      processes.each do |process|
        process.remove_example(spec_id)
      end
    end

    def total_examples
      return 0 if processes.empty?

      processes.collect(&:total_examples).sum
    end

    def clear
      @processes = Concurrent::Hash.new
      @run_command = nil
    end

    def end_time
      return nil if processes.empty? || processes.collect(&:end_time).any?(&:nil?)

      processes.collect(&:end_time).max
    end

    def run_time
      return '00:00:00' if processes.empty?

      time_diff = start_time - (end_time || Time.now)
      Time.at(time_diff.to_i.abs).utc.strftime '%H:%M:%S'
    end

    def running_parallel?
      running_parallel
    end

    class TestSuiteStatus
      attr_reader :test_suite

      def initialize(test_suite)
        @test_suite = test_suite
      end

      def execution_status
        if test_suite.processes.empty?
          :inactive
        elsif !test_execution_complete?
          :running
        elsif total_failed_examples.zero?
          :passed
        else
          :failed
        end
      end

      def total_finished_examples
        return 0 if test_suite.processes.empty?

        test_suite.processes.map { |process| process.status.total_finished_examples }.sum
      end

      def total_running_examples
        return 0 if test_suite.processes.empty?

        test_suite.processes.map { |process| process.status.total_running_examples }.sum
      end

      def total_unfinished_examples
        test_suite.total_examples - total_finished_examples
      end

      def total_passed_examples
        return 0 if test_suite.processes.empty?

        test_suite.processes.map { |process| process.status.total_passed_examples }.sum
      end

      def total_failed_examples
        return 0 if test_suite.processes.empty?

        test_suite.processes.map { |process| process.status.total_failed_examples }.sum
      end

      def total_pending_examples
        return 0 if test_suite.processes.empty?

        test_suite.processes.map { |process| process.status.total_pending_examples }.sum
      end

      def progress_in_percent
        return 0 if test_suite.total_examples.zero?

        ((total_finished_examples.to_f / test_suite.total_examples) * 100).to_i
      end

      def percentage_of_passed_examples
        return 0 if test_suite.total_examples.zero?

        (((total_passed_examples.to_f / test_suite.total_examples) * 100)).ceil
      end

      def percentage_of_failed_examples
        return 0 if test_suite.total_examples.zero?

        (((total_failed_examples.to_f / test_suite.total_examples) * 100)).ceil
      end

      def percentage_of_pending_examples
        return 0 if test_suite.total_examples.zero?

        (((total_pending_examples.to_f / test_suite.total_examples) * 100)).ceil
      end

      def test_execution_complete?
        test_suite.total_examples.positive? && (test_suite.total_examples == total_finished_examples)
      end

      def early_stopped_processes
        return [] if test_suite.total_examples.zero?

        test_suite.processes.select { |process| process.status.test_execution_stopped_early? }
      end

    end
  end

  class TestSuiteServer
    include Singleton

    SERVER_URI = 'druby://localhost:8787'
    def initialize
      fork do
        DRb.install_id_conv(DRb::TimerIdConv.new(600))
        DRb.start_service(SERVER_URI, TestSuite.new)
        DRb.thread.join
      end
    end
  end
end
