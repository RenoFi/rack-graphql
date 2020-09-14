require 'bundler/setup'
require 'pry'
require 'rack-graphql'
require 'rack/test'
require 'ap'

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.include Rack::Test::Methods, type: :request
end

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

class TestSchema < GraphQL::Schema
  query TestQueryType
end

class TestContextHandler
  def self.call(*)
    { foo: 'bar' }
  end
end

def app
  RackGraphql::Application.call(
    schema: TestSchema,
    context_handler: TestContextHandler,
  )
end

def json_response
  Oj.load(last_response.body)
rescue
  puts last_response.inspect
  raise
end
