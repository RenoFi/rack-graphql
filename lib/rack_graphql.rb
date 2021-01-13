require 'oj'
require 'rack'
require 'graphql'

require 'rack_graphql/version'
require 'rack_graphql/exceptions'
require 'rack_graphql/health_response_builder'
require 'rack_graphql/middleware'
require 'rack_graphql/application'

module RackGraphql
  class << self
    def log_exception_backtrace
      return @log_exception_backtrace unless @log_exception_backtrace.nil?

      %w[1 true].include?(ENV['RACK_GRAPHQL_LOG_EXCEPTION_BACKTRACE'].to_s)
    end

    def rescue_exceptions_with_500_json
      return @rescue_exceptions_with_500_json unless @rescue_exceptions_with_500_json.nil?

      %w[1 true].include?(ENV['RACK_GRAPHQL_RESCUE_EXCEPTIONS'].to_s) || ENV['RACK_GRAPHQL_RESCUE_EXCEPTIONS'].nil?
    end

    attr_writer :log_exception_backtrace, :rescue_exceptions_with_500_json
  end
end
