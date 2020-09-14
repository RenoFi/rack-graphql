module RackGraphql
  class Application
    def self.call(
      schema:,
      app_name: 'rack-graphql-service',
      logger: nil,
      context_handler: nil,
      log_exception_backtrace: RackGraphql.log_exception_backtrace,
      health_route: true,
      health_response_builder: RackGraphql::HealthResponseBuilder
    )

      ::Rack::Builder.new do
        map '/graphql' do
          run RackGraphql::Middleware.new(schema: schema, context_handler: context_handler, log_exception_backtrace: log_exception_backtrace, logger: logger)
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
