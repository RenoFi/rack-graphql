RSpec.describe RackGraphql::Application do
  describe '.call' do
    subject { described_class.call(schema: GraphQL::Schema, app_name: 'rack-graphql-service') }

    it do
      expect(subject).to be_a(Rack::Builder)
    end
  end
end
