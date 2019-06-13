RSpec.describe "/graphql request for regular execute", type: :request do
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
      "query" => query,
      "variables" => variables
    }
  end

  describe "valid params" do
    before do
      post "/graphql", MultiJson.dump(params)
    end

    it do
      expect(last_response.status).to eq(200)
      expect(json_response["data"]["result"]["status"]).to eq("ok")
    end
  end

  describe "variables are hash" do
    let(:variables) { { foo: "bar" } }

    before do
      post "/graphql", MultiJson.dump(params)
    end

    it do
      expect(last_response.status).to eq(200)
      expect(json_response["data"]["result"]["status"]).to eq("ok")
    end
  end

  describe "variables are empty string" do
    let(:variables) { "" }

    before do
      post "/graphql", MultiJson.dump(params)
    end

    it do
      expect(last_response.status).to eq(200)
      expect(json_response["data"]["result"]["status"]).to eq("ok")
    end
  end

  describe "variables are invalid json" do
    let(:variables) { "!@#asdf" }

    before do
      post "/graphql", MultiJson.dump(params)
    end

    it do
      expect(last_response.status).to eq(400)
    end
  end

  describe "variables are unsupported type" do
    let(:variables) { 1 }

    before do
      post "/graphql", MultiJson.dump(params)
    end

    it do
      expect(last_response.status).to eq(400)
    end
  end

  describe "get request" do
    before do
      get "/graphql", MultiJson.dump(params)
    end

    it do
      expect(last_response.status).to eq(406)
    end
  end

  describe "put request" do
    before do
      put "/graphql", MultiJson.dump(params)
    end

    it do
      expect(last_response.status).to eq(406)
    end
  end

  describe "invalid params" do
    before do
      post "/graphql", params: "!asdf#"
    end

    it do
      expect(last_response.status).to eq(200)
      expect(json_response["errors"]).not_to be_nil
      expect(json_response["errors"]).not_to be_empty
      expect(json_response["errors"][0]["message"]).to eq("No query string was present")
    end
  end
end
