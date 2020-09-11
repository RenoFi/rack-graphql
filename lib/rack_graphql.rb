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
    attr_accessor :log_exception_backtrace
  end

  self.log_exception_backtrace = true
end
