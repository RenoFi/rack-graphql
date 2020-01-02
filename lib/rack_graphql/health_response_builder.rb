module RackGraphql
  class HealthResponseBuilder
    def initialize(app_name:, env: {})
      @app_name = app_name
      @request = Rack::Request.new(env)
    end

    def build
      [200, headers, [body]]
    end

    private

    attr_reader :app_name, :request

    def headers
      { 'Content-Type' => 'application/json' }
    end

    def body
      Oj.dump(
        'status'     => 'ok',
        'request_ip' => request.ip,
        'app_name'   => app_name,
        'app_env'    => ENV['RACK_ENV'],
        'host'       => ENV['HOSTNAME'],
        'revision'   => ENV['REVISION']
      )
    end
  end
end
