module RackGraphql
  class Middleware
    def initialize(schema:, app_name: nil, context_handler: nil, logger: nil, log_exception_backtrace: RackGraphql.log_exception_backtrace)
      @schema = schema
      @app_name = app_name
      @context_handler = context_handler || ->(_) {}
      @logger = logger
      @log_exception_backtrace = log_exception_backtrace
    end

    def call(env)
      return [406, {}, []] unless post_request?(env)

      params = post_data(env)

      return [400, {}, []] unless params.is_a?(Hash)

      variables = ensure_hash(params['variables'])
      operation_name = params['operationName']
      context = context_handler.call(env)

      log("Executing with params: #{params.inspect}, operationName: #{operation_name}, variables: #{variables.inspect}")
      result = execute(params: params, operation_name: operation_name, variables: variables, context: context)

      [
        200,
        response_headers(result),
        [response_body(result)]
      ]
    rescue AmbiguousParamError => e
      exception_string = dump_exception(e)
      log(exception_string)
      env[Rack::RACK_ERRORS].puts(exception_string)
      env[Rack::RACK_ERRORS].flush
      [
        400,
        { 'Content-Type' => 'application/json' },
        [Oj.dump({})]
      ]
    rescue StandardError, LoadError, SyntaxError => e
      # To respect the graphql spec, all errors need to be returned as json.
      # It needs to take Rack::ShowExceptions role of catching all exceptions raised by the app.
      exception_string = dump_exception(e)
      log(exception_string)
      env[Rack::RACK_ERRORS].puts(exception_string)
      env[Rack::RACK_ERRORS].flush
      [
        500,
        { 'Content-Type' => 'application/json' },
        [Oj.dump('errors' => [exception_hash(e)])]
      ]
    ensure
      ActiveRecord::Base.clear_active_connections! if defined?(ActiveRecord::Base)
    end

    private

    attr_reader :schema, :app_name, :logger, :context_handler, :log_exception_backtrace

    def post_request?(env)
      env['REQUEST_METHOD'] == 'POST'
    end

    def post_data(env)
      ::Oj.load(env['rack.input'].gets.to_s)
    rescue Oj::ParseError
      nil
    end

    # Handle form data, JSON body, or a blank value
    def ensure_hash(ambiguous_param)
      case ambiguous_param
      when String
        return {} if ambiguous_param.empty?

        begin
          ensure_hash(Oj.load(ambiguous_param))
        rescue Oj::ParseError
          raise AmbiguousParamError, "Unexpected parameter: #{ambiguous_param}"
        end
      when Hash
        ambiguous_param
      when nil
        {}
      else
        fail AmbiguousParamError, "Unexpected parameter: #{ambiguous_param}"
      end
    end

    def execute(params:, operation_name:, variables:, context:)
      if valid_multiplex?(params)
        execute_multi(params['_json'], operation_name: operation_name, variables: variables, context: context)
      else
        execute_single(params['query'], operation_name: operation_name, variables: variables, context: context)
      end
    end

    def execute_single(query, operation_name:, variables:, context:)
      schema.execute(query, operation_name: operation_name, variables: variables, context: context)
    end

    def valid_multiplex?(params)
      params['_json'].is_a?(Array) && params['_json'].all? { |j| j.is_a?(Hash) }
    end

    def execute_multi(queries_params, operation_name:, variables:, context:)
      queries = queries_params.map do |param|
        {
          query: param['query'],
          operation_name: operation_name,
          variables: variables,
          context: context
        }
      end

      schema.multiplex(queries)
    end

    def response_headers(result = nil)
      {
        'Access-Control-Expose-Headers' => 'X-Subscription-ID',
        'Content-Type' => 'application/json'
      }.tap do |headers|
        headers['X-Subscription-ID'] = result.context[:subscription_id] if result_subscription?(result)
      end
    end

    def response_body(result = nil)
      if result_subscription?(result)
        body = result.to_h
        body["data"] ||= {}
        body["data"][result.query.operation_name] ||= nil
        body["data"]["subscriptionId"] = result.context[:subscription_id]
      elsif result.is_a?(Array)
        body = result.map(&:to_h)
      else
        body = result.to_h
      end
      Oj.dump(body)
    end

    def result_subscription?(result)
      return false unless result.is_a?(GraphQL::Query::Result)

      result.subscription?
    end

    def log(message)
      return unless logger
      logger.debug("[rack-graphql] #{message}")
    end

    # Based on https://github.com/rack/rack/blob/master/lib/rack/show_exceptions.rb
    def dump_exception(exception)
      string = "#{exception.class}: #{exception.message}\n"
      string << exception.backtrace.map { |l| "\t#{l}" }.join("\n") if log_exception_backtrace
      string
    end

    def exception_hash(exception)
      {
        'app_name' => app_name,
        'message' => "#{exception.class}: #{exception.message}",
        'backtrace' => log_exception_backtrace ? exception.backtrace : "[FILTERED]"
      }
    end
  end
end
