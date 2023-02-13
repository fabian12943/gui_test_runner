module GUITestRunner
  module WebApplicationHelpers
    def h(text)
      Rack::Utils.escape_html(text)
    end
  end
end
