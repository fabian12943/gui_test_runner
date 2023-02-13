# frozen_string_literal: true

require 'gui_test_runner/rspec/exception_presenter' if defined?(RSpec)
require 'gui_test_runner/rspec/failed_example_notification' if defined?(RSpec)

module GUITestRunner
  class ExampleAdapter
    attr_reader :notification, :example, :metadata, :execution_result

    def initialize(notification)
      @notification = notification
      @example = notification.example
      @metadata = OpenStruct.new(example.metadata)
      @execution_result = example.execution_result
    end

    def spec_id
      example.id
    end

    def description
      example.description
    end

    def full_description
      example.full_description
    end

    def file_path
      example.file_path
    end

    def absolute_file_path
      metadata.absolute_file_path
    end

    def line_number
      metadata.line_number
    end

    def type
      file_path[%r{/spec/([^/]*)/.*}, 1] || 'others'
    end

    def source_code
      source_string = metadata.block.source
      array = source_string.split(/\n/)
      leading_whitespaces = array[0][/\A */].size
      array.map do |string|
        if string != ''
          string[leading_whitespaces..]
        else
          ''
        end
      end
    end

    def capybara_feature
      metadata.capybara_feature
    end

    def javascript_feature
      metadata.js
    end
  end

  class RunningExampleAdapter < ExampleAdapter
  end

  class FinishedExampleAdapter < ExampleAdapter
    def run_time
      execution_result.run_time
    end

    def screenshots
      metadata.screenshot
    end
  end

  class PassedExampleAdapter < FinishedExampleAdapter
  end

  class FailedExampleAdapter < FinishedExampleAdapter
    attr_reader :exception

    def initialize(notification)
      super(notification)
      @exception = example.exception
    end

    def exception_message
      exception.message
    end

    def failed_lines
      notification.failed_lines
    end

    def failed_line_number
      notification.failed_line_number
    end

    def backtrace
      exception.backtrace
    end
  end

  class PendingExampleAdapter < FinishedExampleAdapter
  end
end


