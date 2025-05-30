module RackGraphql
  class Middleware
    DEFAULT_STATUS_CODE = 200
    DEFAULT_ERROR_STATUS_CODE = 500
    STATUS_CODE_HEADER_NAME = 'X-Http-Status-Code'.freeze
    SUBSCRIPTION_ID_HEADER_NAME = 'X-Subscription-ID'.freeze
    NULL_BYTE = '\u0000'.freeze

    def initialize(
      schema:,
      app_name: nil,
      context_handler: nil,
      logger: nil,
      log_exception_backtrace: RackGraphql.log_exception_backtrace,
      re_raise_exceptions: false,
      error_status_code_map: {},
      request_epilogue: -> {},
      secret_scrubber: nil
    )
      @schema = schema
      @app_name = app_name
      @context_handler = context_handler || ->(_) {}
      @logger = logger
      @log_exception_backtrace = log_exception_backtrace
      @re_raise_exceptions = re_raise_exceptions
      @error_status_code_map = error_status_code_map
      @request_epilogue = request_epilogue || -> {}
      @secret_scrubber = secret_scrubber || ->(value) { value }
    end

    def call(env)
      return [406, {}, []] unless post_request?(env)

      params = post_data(env)

      return [400, {}, []] unless params.is_a?(Hash)

      variables = ensure_hash(params['variables'])
      operation_name = params['operationName']
      context = context_handler.call(env)

      log("Executing with params: #{secret_scrubber.call(params)}, operationName: #{operation_name}, variables: #{secret_scrubber.call(variables)}")
      result = execute(params:, operation_name:, variables:, context:)
      status_code = response_status(result)

      [
        status_code,
        response_headers(result, status_code:),
        [response_body(result)]
      ]
    rescue AmbiguousParamError => e
      exception_string = dump_exception(e)
      log_error(exception_string)
      env[Rack::RACK_ERRORS].puts(exception_string)
      env[Rack::RACK_ERRORS].flush
      [
        400,
        { 'Content-Type' => 'application/json', STATUS_CODE_HEADER_NAME => 400 },
        [JSON.dump({})]
      ]
    rescue StandardError, LoadError, SyntaxError => e
      # To respect the graphql spec, all errors need to be returned as json.
      # By default exceptions are not re-raised,
      # so they cannot be caught by error tracking rack middlewares.
      # You can change this behavior via `re_raise_exceptions` argument.
      exception_string = dump_exception(e)
      log_error(exception_string)

      raise e if re_raise_exceptions

      env[Rack::RACK_ERRORS].puts(exception_string)
      env[Rack::RACK_ERRORS].flush

      status_code = error_status_code_map[e.class] || DEFAULT_ERROR_STATUS_CODE
      [
        status_code,
        { 'Content-Type' => 'application/json', STATUS_CODE_HEADER_NAME => status_code },
        [JSON.dump('errors' => [exception_hash(e)])]
      ]
    ensure
      request_epilogue.call
    end

    private

    attr_reader :schema, :app_name, :logger, :context_handler,
      :log_exception_backtrace, :error_status_code_map,
      :re_raise_exceptions, :request_epilogue, :secret_scrubber

    def post_request?(env)
      env['REQUEST_METHOD'] == 'POST'
    end

    def post_data(env)
      payload = env['rack.input'].read.to_s
      return nil if payload.index(NULL_BYTE)

      ::JSON.parse(payload)
    rescue JSON::ParserError
      nil
    end

    # Handle form data, JSON body, or a blank value
    def ensure_hash(ambiguous_param)
      case ambiguous_param
      when String
        return {} if ambiguous_param.empty?

        begin
          ensure_hash(JSON.parse(ambiguous_param))
        rescue JSON::ParserError
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
        execute_multi(params['_json'], operation_name:, variables:, context:)
      else
        execute_single(params['query'], operation_name:, variables:, context:)
      end
    end

    def execute_single(query, operation_name:, variables:, context:)
      schema.execute(query, operation_name:, variables:, context:)
    end

    def valid_multiplex?(params)
      params['_json'].is_a?(Array) && params['_json'].all? { |j| j.is_a?(Hash) }
    end

    def execute_multi(queries_params, operation_name:, variables:, context:)
      queries = queries_params.map do |param|
        {
          query: param['query'],
          operation_name:,
          variables:,
          context:
        }
      end

      schema.multiplex(queries)
    end

    def response_headers(result = nil, status_code: DEFAULT_STATUS_CODE)
      headers = { STATUS_CODE_HEADER_NAME => status_code }
      headers[SUBSCRIPTION_ID_HEADER_NAME] = result.context[:subscription_id] if result_subscription?(result)
      result_collection = result.is_a?(Array) ? result : [result]
      result_collection.each do |part|
        headers.merge!(part.context[:headers]) if part.context[:headers].is_a?(Hash)
      end
      headers["Access-Control-Expose-Headers"] = [SUBSCRIPTION_ID_HEADER_NAME, STATUS_CODE_HEADER_NAME].join(", ")
      headers["Content-Type"] = "application/json"
      headers
    end

    def response_status(result)
      return DEFAULT_STATUS_CODE if result.is_a?(Array)

      errors = result.to_h["errors"] || []
      errors.map { |e| e["http_status"] }.compact.first || DEFAULT_STATUS_CODE
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
      JSON.dump(body)
    end

    def result_subscription?(result)
      return false unless result.is_a?(GraphQL::Query::Result)

      result.subscription?
    end

    def log(message)
      logger&.info("[rack-graphql] #{message}")
    end

    def log_error(message)
      logger&.error("[rack-graphql] #{message}")
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
