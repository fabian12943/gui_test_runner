# frozen_string_literal: true

require 'active_support/inflector'
require_relative 'rspec_adapters'

module GUITestRunner
  class Example
    RSPEC_ADAPTER_CLASS = ExampleAdapter
    ATTRIBUTES_FROM_RSPEC = %i[description full_description file_path absolute_file_path line_number type
                               source_code capybara_feature javascript_feature].freeze
    SEARCHABLE_ATTRIBUTES = %i[full_description location].freeze

    attr_accessor :process
    attr_reader :spec_id, :status, :updated_at, *ATTRIBUTES_FROM_RSPEC

    def initialize(spec_id, attributes = {})
      @spec_id = spec_id
      @status = nil
      @execution_finished = false
      @process = nil
      @updated_at = Time.now

      self.class::ATTRIBUTES_FROM_RSPEC.each do |attribute_name|
        instance_variable_set("@#{attribute_name}", attributes.fetch(attribute_name, nil))
      end
    end

    def capybara_feature?
      @capybara_feature
    end

    def javascript_feature?
      @javascript_feature
    end

    def execution_finished?
      @execution_finished
    end

    def parameterized_spec_id
      spec_id.parameterize
    end

    def location
      "#{file_path}:#{line_number}"
    end

    def absolute_location
      "#{absolute_file_path}:#{line_number}"
    end

    def searchable_values
      SEARCHABLE_ATTRIBUTES.map { |attribute| send(attribute) }
    end

    def self.from_rspec_notification(notification)
      adapter = self::RSPEC_ADAPTER_CLASS.new(notification)
      attributes = {}
      self::ATTRIBUTES_FROM_RSPEC.each do |attribute_name|
        attributes[attribute_name] = adapter.send(attribute_name)
      end
      new(adapter.spec_id.parameterize, attributes)
    end
  end

  class RunningExample < Example
    RSPEC_ADAPTER_CLASS = RunningExampleAdapter

    attr_reader(*ATTRIBUTES_FROM_RSPEC)

    def initialize(spec_id, attributes = {})
      super(spec_id, attributes)
      @status = :running
      @execution_finished = false
    end
  end

  class FinishedExample < Example
    RSPEC_ADAPTER_CLASS = FinishedExampleAdapter
    ATTRIBUTES_FROM_RSPEC += %i[run_time screenshots].freeze

    attr_reader(*ATTRIBUTES_FROM_RSPEC)

    def initialize(spec_id, attributes = {})
      super(spec_id, attributes)
      @status = :finished
      @execution_finished = true
    end
  end

  class PassedExample < FinishedExample
    RSPEC_ADAPTER_CLASS = PassedExampleAdapter

    attr_reader(*ATTRIBUTES_FROM_RSPEC)

    def initialize(spec_id, attributes = {})
      super(spec_id, attributes)
      @status = :passed
    end
  end

  class FailedExample < FinishedExample
    RSPEC_ADAPTER_CLASS = FailedExampleAdapter
    ATTRIBUTES_FROM_RSPEC += %i[exception_message failed_lines failed_line_number backtrace].freeze

    attr_reader(*ATTRIBUTES_FROM_RSPEC)

    def initialize(spec_id, attributes = {})
      super(spec_id, attributes)
      @status = :failed
    end
  end

  class PendingExample < FinishedExample
    RSPEC_ADAPTER_CLASS = PendingExampleAdapter

    attr_reader(*ATTRIBUTES_FROM_RSPEC)

    def initialize(spec_id, attributes = {})
      super(spec_id, attributes)
      @status = :pending
    end
  end
end
