module RackGraphql
  class Application
    def self.call(
      schema:,
      app_name: 'rack-graphql-service',
      logger: nil,
      context_handler: nil,
      re_raise_exceptions: false,
      log_exception_backtrace: RackGraphql.log_exception_backtrace,
      health_route: true,
      health_response_builder: RackGraphql::HealthResponseBuilder,
      health_on_root_path: health_route,
      root_path_app: nil,
      error_status_code_map: {},
      request_epilogue: -> {}
    )
      ::Rack::Builder.new do
        map '/graphql' do
          run RackGraphql::Middleware.new(
            app_name:,
            schema:,
            context_handler:,
            re_raise_exceptions:,
            logger:,
            log_exception_backtrace:,
            error_status_code_map:,
            request_epilogue:,
          )
        end

        if health_route
          map '/health' do
            run ->(env) { health_response_builder.new(app_name:, env:).build }
          end

          map '/healthz' do
            run ->(env) { health_response_builder.new(app_name:, env:).build }
          end
        end

        if root_path_app
          map '/' do
            run root_path_app
          end
        elsif health_on_root_path
          map '/' do
            run ->(env) { health_response_builder.new(app_name:, env:).build }
          end
        end
      end
    end
  end
end
