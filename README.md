[![Gem Version](https://badge.fury.io/rb/rack-graphql.svg)](https://rubygems.org/gems/rack-graphql)
[![Build Status](https://travis-ci.org/RenoFi/rack-graphql.svg?branch=master)](https://travis-ci.org/RenoFi/rack-graphql)

# rack-graphql

Rack middleware implementing graphql endpoint for ruby (non-`ActionController`) services. It uses pure rack and none of `ActionController` or `Sinatra` is required. By default it implements health route on `/health` and `/`, since it's only expected to be used on graphql-only services.

It also handles [subscriptions](https://graphql-ruby.org/guides#subscriptions-guides) and [multiplex](https://graphql-ruby.org/queries/multiplex.html).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-graphql'
```

## Usage example

Add to your `config.ru` file

```ruby
run RackGraphql::Application.call(                    
  schema: YourGraqphqlSchema,                 # required
  app_name: 'your-service-name',              # optional, used for health route
  context_handler: YourGraphqlContextHandler, # optional, empty proc by default
  health_route: true,                     # optional, true by default
)
```

`context_handler` can be a class, object or proc. It only must respond to `call` merhod taking `env` as an argument. It is supposed to decode request properties to graphql context (eg. jwt token to user object, as shown below).

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

      UserRepo.find_by_id(payload['user_id])
    end
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RenoFi/rack-graphql. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
