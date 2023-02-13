# frozen_string_literal: true

module RSpec
  module Core
    module Formatters
      class ExceptionPresenter
        def failed_lines
          read_failed_lines
        end

        def failed_line_number
          matching_line = find_failed_line

          file_and_line_number = matching_line.match(/(.+?):(\d+)(|:\d+)/)
          file_path, line_number = file_and_line_number[1..2]
          line_number.to_i
        end
      end
    end
  end
end
