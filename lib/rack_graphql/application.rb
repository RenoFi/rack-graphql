module RackGraphql
  class Application
    # rubocop:disable Metrics/ParameterLists
    def self.call(
      schema:,
      app_name: 'rack-graphql-service',
      logger: nil,
      context_handler: nil,
      log_exception_backtrace: RackGraphql.log_exception_backtrace,
      health_route: true,
      health_response_builder: RackGraphql::HealthResponseBuilder,
      error_status_code_map: {},
      error_response_middleware: RackGraphql::ExceptionJSONResponseMiddleware,
      middlewares: []
    )
      # rubocop:enable Metrics/ParameterLists

      ::Rack::Builder.new do
        if error_response_middleware
          use(
            error_response_middleware,
            app_name: app_name,
            error_status_code_map: error_status_code_map,
            log_exception_backtrace: log_exception_backtrace
          )
        end
        use(::RackGraphql::LogErrorsMiddleware, logger: logger, log_exception_backtrace: log_exception_backtrace)
        middlewares.each { |middleware| use middleware }

        map '/graphql' do
          run RackGraphql::Middleware.new(
            app_name: app_name,
            schema: schema,
            context_handler: context_handler,
            logger: logger,
          )
        end

        if health_route
          map '/health' do
            run ->(env) { health_response_builder.new(app_name: app_name, env: env).build }
          end

          map '/healthz' do
            run ->(env) { health_response_builder.new(app_name: app_name, env: env).build }
          end

          map '/' do
            run ->(env) { health_response_builder.new(app_name: app_name, env: env).build }
          end
        end
      end
    end
  end
end
