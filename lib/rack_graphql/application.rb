module RackGraphql
  class Application
    def self.call(schema:, context_handler: nil)
      ::Rack::Builder.new do
        map '/graphql' do
          run RackGraphql::Middleware.new(schema: schema, context_handler: context_handler)
        end
      end
    end
  end
end
