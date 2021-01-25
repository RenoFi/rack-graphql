require 'oj'
require 'rack'
require 'graphql'

# Timeout needs to be manually required before following fix is released:
# https://github.com/rmosolgo/graphql-ruby/commit/56abba472dbb48a1f8445d41f928bea72b5148e9
require 'timeout'

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

    attr_writer :log_exception_backtrace
  end
end
