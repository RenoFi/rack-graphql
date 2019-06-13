RSpec.describe "/graphql request for multiplex execute", type: :request do
  describe "valid params" do
    let(:query1) do
      %|{
        result1: health {
          status
        }
      }|
    end

    let(:query2) do
      %|{
        result2: health {
          status
        }
      }|
    end

    let(:params) do
      {
        _json: [{ query: query1 }, { query: query2 }]
      }
    end

    before do
      post "/graphql", MultiJson.dump(params)
    end

    it do
      expect(last_response.status).to eq(200)
      expect(json_response.size).to eq(2)
      expect(json_response[0]["data"]["result1"]["status"]).to eq("ok")
      expect(json_response[1]["data"]["result2"]["status"]).to eq("ok")
    end
  end

  describe "invalid params" do
    let(:params) do
      {
        _json: ["hello"]
      }
    end

    before do
      post "/graphql", MultiJson.dump(params)
    end

    it do
      expect(last_response.status).to eq(200)
      expect(json_response["errors"]).not_to be_nil
      expect(json_response["errors"]).not_to be_empty
      expect(json_response["errors"][0]["message"]).to eq("No query string was present")
    end
  end
end
