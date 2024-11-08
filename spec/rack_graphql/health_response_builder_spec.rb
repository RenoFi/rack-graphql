RSpec.describe RackGraphql::HealthResponseBuilder do
  describe '#build' do
    subject { described_class.new(app_name: 'rack-graphql-service').build }

    let(:body) { JSON.parse(subject[2].first) }

    it do
      expect(subject[0]).to eq(200)
      expect(subject[1]).to eq('Content-Type' => 'application/json')
      expect(body.keys).to match_array(%w[status app_name app_env host revision request_ip])
    end
  end
end
