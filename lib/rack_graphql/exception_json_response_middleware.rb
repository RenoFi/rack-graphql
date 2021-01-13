module RackGraphql
  class ExceptionJSONResponseMiddleware
    DEFAULT_ERROR_STATUS_CODE = 500

    def initialize(app, app_name:, error_status_code_map:, log_exception_backtrace:)
      @app = app
      @app_name = app_name
      @error_status_code_map = error_status_code_map
      @log_exception_backtrace = log_exception_backtrace
    end

    def call(env)
      @app.call(env)
    rescue AmbiguousParamError
      [
        400,
        { 'Content-Type' => 'application/json' },
        [Oj.dump({})]
      ]
    rescue StandardError, LoadError, SyntaxError => e
      [
        error_status_code_map[e.class] || DEFAULT_ERROR_STATUS_CODE,
        { 'Content-Type' => 'application/json' },
        [Oj.dump('errors' => [exception_hash(e)])]
      ]
    ensure
      ActiveRecord::Base.clear_active_connections! if defined?(ActiveRecord::Base)
    end

    private

    attr_reader :app_name, :error_status_code_map, :log_exception_backtrace

    def exception_hash(exception)
      {
        'app_name' => app_name,
        'message' => "#{exception.class}: #{exception.message}",
        'backtrace' => log_exception_backtrace ? exception.backtrace : "[FILTERED]"
      }
    end
  end
end
