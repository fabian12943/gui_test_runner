# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/content_for'
require 'sinatra/namespace'
require 'haml'
require 'byebug'
require 'drb/drb'
require 'rake'
require 'gui_test_runner/tasks'

require_relative 'helpers'
require_relative '../formatter'
require_relative '../examples/examples'
require_relative '../test_suite'

module GUITestRunner
  class WebApplication < Sinatra::Application
    helpers WebApplicationHelpers
    helpers Sinatra::ContentFor

    configure do
      set :port, 5400
      set :server, :thin
      set :root, File.expand_path('../../../web', __dir__.to_s)
      set :haml, { escape_html: false }
      set :connections, []
    end

    attr_reader :test_suite, :websockets

    def initialize(app = nil, **_kwargs)
      super
      TestSuiteServer.instance
      DRb.start_service
      @test_suite = DRbObject.new_with_uri(TestSuiteServer::SERVER_URI)
    end

    get '/' do
      redirect to('/examples')
    end

    get '/examples' do
      examples = test_suite.all_examples
      haml :overview, locals: { examples: examples, selected_example: nil }
    end

    get '/examples/rerun' do
      failed_examples_only = params['failed_examples_only'] || false
      fork do
        if failed_examples_only
          Rake::Task['gui_test_runner:rerun_failed_examples'].invoke
        else
          Rake::Task['gui_test_runner:rerun_all_examples'].invoke
        end
      end
      204
    end

    post '/examples/list/selection' do
      spec_ids = JSON.parse(params['spec_ids'])
      examples = test_suite.examples(spec_ids)
      haml :examples_list_tab, locals: { examples: examples }, layout: false
    end

    get '/examples/:spec_id' do
      examples = test_suite.all_examples
      selected_example = test_suite.example(params['spec_id'])
      haml :overview, locals: { examples: examples, selected_example: selected_example }
    end

    get '/examples/:spec_id/rerun' do
      example = test_suite.example(params['spec_id'])
      fork { Rake::Task['gui_test_runner:rerun_example'].execute(example_path: example.absolute_location) }
      204
    end

    get '/examples/:spec_id/results' do
      example = test_suite.example(params['spec_id'])
      haml :example_results_tab, locals: { example: example }, layout: false
    end

    get '/examples/:spec_id/rubymine/open' do
      example = test_suite.example(params['spec_id'])
      fork { exec "rubymine --line #{example.line_number} #{example.absolute_file_path}" }
      204
    end

    get '/test_progress' do
      haml :progress, layout: false
    end

    get '/examples/:spec_id/screenshots/:screenshot_type' do
      example = test_suite.example(params['spec_id'])
      file = File.open(example.screenshots[params['screenshot_type'].to_sym])
      send_file(file)
    end

    get '/stream', provides: 'text/event-stream' do
      stream :keep_open do |out|
        settings.connections << out
        out.callback { settings.connections.delete(out) }
      end
    end

    post '/start_of_test_suite' do
      event = :start_of_test_suite
      data = { rerun: params['rerun'] }
      stream_event(event, data)
    end

    post '/end_of_test_suite' do
      event = :end_of_test_suite
      stream_event(event)
    end

    post '/new_example/:spec_id' do
      event = :new_example
      data = { spec_id: params['spec_id'], example_type: params['example_type'] }
      stream_event(event, data)
    end

    post '/update_example/:spec_id/:status' do
      event = :update_example
      data = { spec_id: params['spec_id'], status: params['status'] }
      stream_event(event, data)
    end

    def stream_event(event, data = "")
      settings.connections.each { |out| out << "event: #{event}" << "\n" << "data: #{data.to_json}" << "\n\n" }
      204
    end

  end
end
