require 'bundler/setup'
require 'pry'
require 'rack-graphql'
require 'rack/test'
require 'ap'
require 'ostruct'

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.before do
    RackGraphql.log_exception_backtrace = true
    ENV['RACK_GRAPHQL_LOG_EXCEPTION_BACKTRACE'] = nil
  end

  config.include Rack::Test::Methods, type: :request
end

TestUnauthorizedError = Class.new(StandardError)
TestCustomError = Class.new(StandardError)

class HealthResponseBuilder
  def self.build
    OpenStruct.new(status: :ok)
  end
end

class HealthResponseType < GraphQL::Schema::Object
  field :status, String, null: false
end

class ProductsResponseType < GraphQL::Schema::Object
  field :products, [String], null: false
end

class TestQueryType < GraphQL::Schema::Object
  field :health, HealthResponseType, null: true do
    description 'Static endpoint used for testing purposes'
  end

  def health
    context[:headers] = { 'X-My-Custom-Header' => 'OK' }
    HealthResponseBuilder.build
  end

  field :search, ProductsResponseType, null: true do
    argument :keyword, String, required: true
    description 'Endpoint with parameters used for testing purposes'
  end

  def search(keyword:)
    OpenStruct.new(
      products: keyword.empty? ? [] : %w[Toothbrush Soap]
    )
  end
end

class TestSchema < GraphQL::Schema
  query TestQueryType

  rescue_from TestUnauthorizedError do |exception|
    ::GraphQL::ExecutionError.new(
      exception.message,
      options: { "http_status" => 403 },
      extensions: {
        "code" => exception.class.to_s,
        "http_status" => 403,
        "details" => exception.message.to_s
      }
    )
  end
end

class TestContextHandler
  def self.call(*)
    { text_context_var: 'test_value' }
  end
end

def app
  RackGraphql::Application.call(
    schema: TestSchema,
    context_handler: TestContextHandler,
    error_status_code_map: { TestCustomError => 418 }
  )
end

def json_response
  JSON.parse(last_response.body)
rescue
  puts last_response.inspect
  raise
end
