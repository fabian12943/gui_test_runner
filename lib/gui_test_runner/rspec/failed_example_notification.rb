# frozen_string_literal: true

module RSpec
  module Core
    module Notifications
      class FailedExampleNotification < ExampleNotification
        def failed_lines
          @exception_presenter.failed_lines.map do |failed_line|
            failed_line.gsub(/\e\[([;\d]+)?m/, '') # removes ANSI colors
          end
        end

        def failed_line_number
          @exception_presenter.failed_line_number
        end
      end
    end
  end
end

