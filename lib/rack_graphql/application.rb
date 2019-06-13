module RackGraphql
  class Application
    def self.call(schema:, app_name: 'graphql-on-rack', context_handler: nil)
      ::Rack::Builder.new do
        map "/graphql" do
          run RackGraphql::Middleware.new(schema: schema, context_handler: context_handler)
        end

        map "/health" do
          run ->(env) { RackGraphql::HealthResponseBuilder.new(app_name: app_name).build }
        end

        map "/" do
          run ->(env) { RackGraphql::HealthResponseBuilder.new(app_name: app_name).build }
        end
      end
    end
  end
end
