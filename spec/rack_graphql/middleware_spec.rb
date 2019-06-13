RSpec.describe RackGraphql::Middleware do
  describe ".call" do
    let(:context_handler) { ->(env) { { bacon: "steak" } } }
    let(:env) { { "rack.input" => double(gets: nil), "REQUEST_METHOD" => request_method } }

    subject { described_class.new(schema: GraphQL::Schema, context_handler: context_handler).call(env) }

    context "non-POST request" do
      let(:request_method) { "PUT" }

      it do
        expect(subject[0]).to eq(406)
      end
    end

    context "POST request" do
      let(:request_method) { "POST" }

      it do
        expect(subject[0]).to eq(200)
        expect(subject[1]).to eq("Content-Type" => "application/json", "Access-Control-Expose-Headers" => "X-Subscription-ID")
      end
    end
  end
end
