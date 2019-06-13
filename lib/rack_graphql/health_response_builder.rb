module RackGraphql
  class HealthResponseBuilder
    def initialize(app_name:)
      @app_name = app_name
    end

    def build
      [200, headers, [body]]
    end

    private

    attr_reader :app_name

    def headers
      { 'Content-Type' => 'application/json' }
    end

    def body
      MultiJson.dump(
        status:   :ok,
        app_name: app_name,
        env:      ENV['RACK_ENV'],
        host:     ENV['HOSTNAME'],
        revision: ENV['REVISION'],
      )
    end
  end
end
