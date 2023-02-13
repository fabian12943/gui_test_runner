# frozen_string_literal: true

require 'drb'
require_relative 'examples'

module GUITestRunner
  class ExampleFactory

    def self.from_rspec_notification(notification)
      case notification.example.execution_result.status
      when nil
        RunningExample.from_rspec_notification(notification)
      when :passed
        PassedExample.from_rspec_notification(notification)
      when :failed
        FailedExample.from_rspec_notification(notification)
      when :pending
        PendingExample.from_rspec_notification(notification)
      end
    end
  end
end
