RSpec.describe RackGraphql::Middleware do
  describe '.call' do
    subject { described_class.new(schema: GraphQL::Schema, context_handler: context_handler).call(env) }

    let(:context_handler) { ->(env) { { bacon: 'steak', env: env } } }
    let(:env) { { 'rack.input' => instance_double(Rack::RewindableInput, gets: Oj.dump({})), 'REQUEST_METHOD' => request_method } }

    describe 'non-POST request' do
      let(:request_method) { 'PUT' }

      it do
        expect(subject[0]).to eq(406)
      end
    end

    describe 'POST request' do
      let(:request_method) { 'POST' }

      it do
        expect(subject[0]).to eq(200)
        expect(subject[1]).to eq('Content-Type' => 'application/json', 'Access-Control-Expose-Headers' => 'X-Subscription-ID')
      end
    end
  end
end
