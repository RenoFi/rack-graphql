[![Gem Version](https://badge.fury.io/rb/rack-graphql.svg)](https://rubygems.org/gems/rack-graphql)
[![Build Status](https://travis-ci.org/RenoFi/rack-graphql.svg?branch=master)](https://travis-ci.org/RenoFi/rack-graphql)

# rack-graphql

`rack-graphql` is designed to build ruby services with graphql api. It provides `/graphql` endpoint and can handle [subscriptions](https://graphql-ruby.org/guides#subscriptions-guides) and [multiplex](https://graphql-ruby.org/queries/multiplex.html).

It works on pure rack and none of `ActionController`/`ActionDispatch`/`ActionPack` or `Sinatra` is required.

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
  schema: YourGraqphqlSchema,                # required
  context_handler: YourGraphqlContextHandler # optional, empty `proc` by default
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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RenoFi/rack-graphql. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
