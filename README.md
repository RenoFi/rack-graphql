[![Gem Version](https://badge.fury.io/rb/rack-graphql.svg)](https://rubygems.org/gems/rack-graphql)
[![Build Status](https://github.com/RenoFi/rack-graphql/actions/workflows/ci.yml/badge.svg)](https://github.com/RenoFi/rack-graphql/actions/workflows/ci.yml?query=branch%3Amain)

# rack-graphql

`rack-graphql` is designed to build ruby services with graphql api. It provides `/graphql` endpoint and can handle [subscriptions](https://graphql-ruby.org/guides#subscriptions-guides) and [multiplex](https://graphql-ruby.org/queries/multiplex.html).

It works on pure rack and none of `ActionController`/`ActionDispatch`/`ActionPack` or `Sinatra` is required. By default it provides health route on `/health` and `/`, which can be disabled.

It can be used together with rails to not make graphql requests be routed with `ActionDispatch` or more pure ruby apps.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-graphql'
```

## Usage example

Add following to your `config.ru` file:

```ruby
run RackGraphql::Application.call(
  schema: YourGraqphqlSchema,                       # required
  app_name: 'your-service-name',                    # optional, used for health endpoint content
  context_handler: YourGraphqlContextHandler,       # optional, empty `proc` by default
  log_exception_backtrace: !A9n.env.production?,    # optional, `false` default
  # `true` when `RACK_GRAPHQL_LOG_EXCEPTION_BACKTRACE` env var is set to `'1'` or `'true'`
  health_route: true,                               # optional, true by default
  health_on_root_path: health_route,                # optional, health_route value by default (mind map '/' is covering '/any/path-123') 
  logger: A9n.logger,                               # optional, not set by default
  error_status_code_map: { IamTeapotError => 418 }, # optional
  re_raise_exceptions: true,                        # optional, false by default
)
```

`context_handler` can be a class, object or proc. It must respond to `call` method taking `env` as an argument. It is supposed to decode or transform request properties to graphql context (eg. jwt token to user object, as shown on an example below).

### Example: using context handler for JWT authentication

```ruby
class GraphqlContextHandler
  class << self
    def call(env)
      payload = decode_payload(env)

      graphql_context_hash(payload)
    end

    private

    def graphql_context_hash(payload)
      {
        current_user: current_user(payload)
      }
    end

    def decode_payload(env)
      jwt = env["HTTP_AUTHORIZATION"].to_s.split(' ').last

      return if jwt.blank?

      DecodeJwt.call(jwt) || {}
    end

    def current_user(payload)
      return unless payload
      return unless payload['user_id']

      UserRepo.find_by_id(payload['user_id'])
    end
  end
end
```

### Logging exception backtrace

RackGraphql catches all errors and respond with 500 code. By default it adds exception backtrace to the response body. If you don't want to have the backtrace in the response set:

```
RackGraphql.log_exception_backtrace = false
```

### Error tracking/reporting

To respect the graphql spec, all errors need to be returned as json and `rack-graphql` catches all exceptions and does NOT re-raise them. You can change this behavior via `re_raise_exceptions` argument.
Because of this, using error tracking middleware (`use Sentry::Rack::CaptureExceptions`, `use Raven::Rack`) does not take any effect for graphql requests.

To use Sentry or other reporting tool for graphql queries, you should handle it on graphql schema level:

```ruby
class MySchema < GraphQL::Schema
  rescue_from StandardError do |e, obj, args, ctx, field|
    extra = {
      args: args,
      field: field.inspect,
      context: ctx
    }
    Sentry.capture_exception(e, extra: extra)
    # re-raise to be handled by rack middleware
    raise
    # or return execution error
    ::GraphQL::ExecutionError.new(
      exception.class.to_s,
      options: { "http_status" => 500 },
      extensions: {
        "code" => exception.class.to_s,
        "http_status" => 500,
        "details" => exception.inspect
      }
    )
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RenoFi/rack-graphql. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
