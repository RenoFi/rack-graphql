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
      error_status_code_map: {}
    )

      ::Rack::Builder.new do
        map '/graphql' do
          run RackGraphql::Middleware.new(
            app_name: app_name,
            schema: schema,
            context_handler: context_handler,
            re_raise_exceptions: re_raise_exceptions,
            logger: logger,
            log_exception_backtrace: log_exception_backtrace,
            error_status_code_map: error_status_code_map,
          )
        end

        if health_route
          map '/health' do
            run ->(env) { health_response_builder.new(app_name: app_name, env: env).build }
          end

          map '/healthz' do
            run ->(env) { health_response_builder.new(app_name: app_name, env: env).build }
          end
        end

        if health_on_root_path
          map '/' do
            run ->(env) { health_response_builder.new(app_name: app_name, env: env).build }
          end
        end
      end
    end
  end
end
