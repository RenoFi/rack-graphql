require "bundler/setup"
require "pry"
require "rack-graphql"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end
end

class FruitType < GraphQL::Schema::Object
  field :id, ID, null: false
  field :name, String, null: false
end

class TestQueryType < GraphQL::Schema::Object
  field :fruits, [FruitType], null: true

  def fruits(page: nil, limit: nil)
    (0..10).map { |i| OpenStruct.new(id: SecureRandom.uuid, name: "Banana #{i}") }
  end
end

class TestSchema < GraphQL::Schema
  query TestQueryType
end
