RSpec.describe '/graphql request for regular execute', type: :request do
  let(:query) do
    %|{
      result: health {
        status
      }
    }|
  end

  let(:variables) { nil }

  let(:params) do
    {
      'query' => query,
      'variables' => variables
    }
  end

  describe 'valid params' do
    before do
      post '/graphql', Oj.dump(params)
    end

    it do
      expect(last_response.status).to eq(200)
      expect(last_response.headers["x-http-status-code"]).to eq(200)
      expect(json_response['data']['result']['status']).to eq('ok')
    end
  end

  describe 'custom execution error and return custom http status code' do
    before do
      expect(HealthResponseBuilder).to receive(:build).and_raise(TestUnauthorizedError.new("omg"))
      post '/graphql', Oj.dump(params)
    end

    it do
      expect(last_response.status).to eq(403)
      expect(last_response.headers["x-http-status-code"]).to eq(403)
      json_response = Oj.load(last_response.body)
      expect(json_response["errors"]).to be_a(Array)
      expect(json_response["errors"]).not_to be_empty
      expect(json_response["errors"].size).to eq(1)
      expect(json_response["errors"][0]).to be_a(Hash)
      expect(json_response["errors"][0]["message"]).to eq("omg")
    end
  end

  describe 'catch custom exception and return custom http status code' do
    before do
      expect(HealthResponseBuilder).to receive(:build).and_raise(TestCustomError.new("omg"))
      post '/graphql', Oj.dump(params)
    end

    it do
      expect(last_response.status).to eq(418)
      expect(last_response.headers["x-http-status-code"]).to eq(418)
      json_response = Oj.load(last_response.body)
      expect(json_response["errors"]).to be_a(Array)
      expect(json_response["errors"]).not_to be_empty
      expect(json_response["errors"].size).to eq(1)
      expect(json_response["errors"][0]).to be_a(Hash)
      expect(json_response["errors"][0]["app_name"]).not_to be_empty
      expect(json_response["errors"][0]["message"]).to eq("TestCustomError: omg")
      expect(json_response["errors"][0]["backtrace"]).to be_a(Array)
    end
  end

  context 'for endpoint with input parameters' do
    let(:query) do
      %|{
      result: search(keyword: "#{keyword}") {
        products
      }
    }|
    end
    let(:keyword) { 'body care' }

    before do
      post '/graphql', Oj.dump(params)
    end

    it 'responds successfully' do
      expect(last_response.status).to eq(200)
      expect(last_response.headers["x-http-status-code"]).to eq(200)
      json_response = Oj.load(last_response.body)

      expect(json_response['data']['result']['products']).to eq(%w[Toothbrush Soap])
    end

    context 'when passed null utf byte as part of input' do
      let(:keyword) { "body\u0000care" }

      it 'responds with bad request' do
        expect(last_response.status).to eq(400)
        expect(last_response.body).to be_empty
      end
    end
  end

  describe 'catch all errors' do
    before do
      expect(HealthResponseBuilder).to receive(:build).and_raise(StandardError.new("omg"))
    end

    context 'when log_exception_backtrace is enabled by setter' do
      before do
        RackGraphql.log_exception_backtrace = true
        post '/graphql', Oj.dump(params)
      end

      it do
        expect(last_response.status).to eq(500)
        json_response = Oj.load(last_response.body)
        expect(json_response["errors"]).to be_a(Array)
        expect(json_response["errors"]).not_to be_empty
        expect(json_response["errors"].size).to eq(1)
        expect(json_response["errors"][0]).to be_a(Hash)
        expect(json_response["errors"][0]["app_name"]).not_to be_empty
        expect(json_response["errors"][0]["message"]).to eq("StandardError: omg")
        expect(json_response["errors"][0]["backtrace"]).to be_a(Array)
      end
    end

    context 'when log_exception_backtrace is enabled by env var' do
      before do
        ENV['RACK_GRAPHQL_LOG_EXCEPTION_BACKTRACE'] = 'true'
        post '/graphql', Oj.dump(params)
      end

      it do
        expect(last_response.status).to eq(500)
        json_response = Oj.load(last_response.body)
        expect(json_response["errors"]).to be_a(Array)
        expect(json_response["errors"]).not_to be_empty
        expect(json_response["errors"].size).to eq(1)
        expect(json_response["errors"][0]).to be_a(Hash)
        expect(json_response["errors"][0]["app_name"]).not_to be_empty
        expect(json_response["errors"][0]["message"]).to eq("StandardError: omg")
        expect(json_response["errors"][0]["backtrace"]).to be_a(Array)
      end
    end

    context 'when log_exception_backtrace is disabled' do
      before do
        RackGraphql.log_exception_backtrace = false
        post '/graphql', Oj.dump(params)
      end

      it do
        expect(last_response.status).to eq(500)
        json_response = Oj.load(last_response.body)
        expect(json_response["errors"]).to be_a(Array)
        expect(json_response["errors"]).not_to be_empty
        expect(json_response["errors"].size).to eq(1)
        expect(json_response["errors"][0]).to be_a(Hash)
        expect(json_response["errors"][0]["app_name"]).not_to be_empty
        expect(json_response["errors"][0]["message"]).to eq("StandardError: omg")
        expect(json_response["errors"][0]["backtrace"]).to eq("[FILTERED]")
      end
    end
  end

  describe 'variables are hash' do
    let(:variables) { { foo: 'bar' } }

    before do
      post '/graphql', Oj.dump(params)
    end

    it do
      expect(last_response.status).to eq(200)
      expect(json_response['data']['result']['status']).to eq('ok')
    end
  end

  describe 'variables are empty string' do
    let(:variables) { '' }

    before do
      post '/graphql', Oj.dump(params)
    end

    it do
      expect(last_response.status).to eq(200)
      expect(json_response['data']['result']['status']).to eq('ok')
    end
  end

  describe 'variables are invalid json' do
    let(:variables) { '!@#asdf' }

    before do
      post '/graphql', Oj.dump(params)
    end

    it do
      expect(last_response.status).to eq(400)
    end
  end

  describe 'nil payload' do
    before do
      post '/graphql'
    end

    it do
      expect(last_response.status).to eq(400)
    end
  end

  describe 'variables are unsupported type' do
    let(:variables) { 1 }

    before do
      post '/graphql', Oj.dump(params)
    end

    it do
      expect(last_response.status).to eq(400)
    end
  end

  describe 'get request' do
    before do
      get '/graphql', Oj.dump(params)
    end

    it do
      expect(last_response.status).to eq(406)
    end
  end

  describe 'put request' do
    before do
      put '/graphql', Oj.dump(params)
    end

    it do
      expect(last_response.status).to eq(406)
    end
  end

  describe 'non-hash body' do
    before do
      post '/graphql', Oj.dump('!asdf#')
    end

    it do
      expect(last_response.status).to eq(400)
    end
  end

  describe 'non-json body' do
    before do
      post '/graphql', params: '!asdf#'
    end

    it do
      expect(last_response.status).to eq(400)
    end
  end

  describe 'empty params' do
    before do
      post '/graphql', Oj.dump({})
    end

    it do
      expect(last_response.status).to eq(200)
      expect(json_response['errors']).not_to be_nil
      expect(json_response['errors']).not_to be_empty
      expect(json_response['errors'][0]['message']).to eq('No query string was present')
    end
  end
end
