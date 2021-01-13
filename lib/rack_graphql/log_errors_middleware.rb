module RackGraphql
  # write exception to logs and re-raise error, to pass to next middlewares
  class LogErrorsMiddleware
    def initialize(app, logger:, log_exception_backtrace: false)
      @app = app
      @logger = logger
      @log_exception_backtrace = log_exception_backtrace
    end

    def call(env)
      @app.call(env)
    rescue StandardError, LoadError, SyntaxError, AmbiguousParamError => e
      log_errors(e, env)
      raise
    end

    private

    attr_reader :log_exception_backtrace, :logger

    def log_errors(exception, env)
      exception_string = dump_exception(exception)
      env[Rack::RACK_ERRORS].puts(exception_string)
      env[Rack::RACK_ERRORS].flush

      log(exception_string) if logger
    end

    # Based on https://github.com/rack/rack/blob/master/lib/rack/show_exceptions.rb
    def dump_exception(exception)
      string = "#{exception.class}: #{exception.message}\n"
      string << exception.backtrace.map { |l| "\t#{l}" }.join("\n") if log_exception_backtrace
      string
    end

    def log(message)
      logger.error("[rack-graphql] #{message}")
    end
  end
end
