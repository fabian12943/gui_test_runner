# frozen_string_literal: true

require 'httparty'

module GUITestRunner
  class ReportUpdater
    APPLICATION_PORT = '5400'

    def self.start_of_test_suite(rerun: false)
      HTTParty.post("http://localhost:#{APPLICATION_PORT}/start_of_test_suite?rerun=#{rerun}")
    end

    def self.end_of_test_suite
      HTTParty.post("http://localhost:#{APPLICATION_PORT}/end_of_test_suite")
    end

    def self.new_example(example)
      HTTParty.post("http://localhost:#{APPLICATION_PORT}/new_example/#{example.parameterized_spec_id}?example_type=#{example.type}")
    end

    def self.update_example(example)
      HTTParty.post("http://localhost:#{APPLICATION_PORT}/update_example/#{example.parameterized_spec_id}/#{example.status}")
    end
  end
end
