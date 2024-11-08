RSpec.describe RackGraphql::Middleware do
  describe '.call' do
    subject { described_class.new(schema: GraphQL::Schema, context_handler:, request_epilogue:).call(env) }

    let(:context_handler) { ->(env) { { bacon: 'steak', env: } } }
    let(:env) { { 'rack.input' => instance_double(Rack::RewindableInput, read: JSON.dump({})), 'REQUEST_METHOD' => request_method } }
    let(:request_epilogue) { -> {} }

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
        expect(subject[1]).to eq(
          'Content-Type' => 'application/json',
          'Access-Control-Expose-Headers' => 'X-Subscription-ID, X-Http-Status-Code',
          'X-Http-Status-Code' => 200
        )
      end
    end

    describe 'request_epilogue' do
      let(:request_method) { 'POST' }

      it do
        expect(request_epilogue).to receive(:call).and_call_original
        subject
      end
    end
  end
end
