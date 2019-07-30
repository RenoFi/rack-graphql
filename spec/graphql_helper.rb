class HealthResponseType < GraphQL::Schema::Object
  field :status, String, null: false
end

class TestQueryType < GraphQL::Schema::Object
  field :health, HealthResponseType, null: true do
    description 'Static endpoint used for testing purposes'
  end

  def health
    OpenStruct.new(status: :ok)
  end
end

class TestSubscription < GraphQL::Schema
end

class TestSchema < GraphQL::Schema
  query TestQueryType
end
