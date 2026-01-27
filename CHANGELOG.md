# CHANGELOG

## 3.10.0 - 2026-01-27
- Ruby 4.0 support. Drop ruby 3.3 support.

## 3.9.0 - 2025-05-29
- Ability to provide secret scrubber, so sensitive values are not logged

## 3.8.0 - 2025-02-05
- Ruby 3.4 support. Drop ruby 3.2 support.

## 3.7.0 - 2024-11-08
- use json gem 2.8+ instead of oj

## 3.6.0 - 2024-04-26
- drop ruby 3.1 support
- pass context.headers to the http reponse

## 3.5.0 - 2024-02-29
- make ruby 3.1 as a minimum ruby version, add ruby 3.3 support

## 3.3.0 - 2023-11-23

- add `request_epilogue` so actions like `ActiveRecord::Base.connection_handler.clear_active_connections!` can be passed manually
- ruby 3.1 is the minimal ruby version

## 3.1.3 - 2023-10-10

- use `ActiveRecord::Base.connection_handler.clear_active_connections!` instead of ActiveRecord::Base.clear_active_connections!`, which is deprecated

## 3.1.1 - 2023-01-17

- Add X-Http-Status-Code to every response, so clients can recognize graphql errors w/o parsing gql response.

## 3.0.1 - 2023-01-17

-  allow running on rack 2.x, so it can work with apps having sinatra installed (sinatra doesn't support rack 3.x)

## 3.0.0 - 2022-12-15

- support rack 3.x and graphql 2.x

## 2.11.0 - 2022-05-25

- change log level to info

## 2.10.1 - 2022-04-02

- Test against ruby 3.1

## 2.9.0 - 2022-03-14

- Drop graphql 1.x support

## 2.8.0 - 2022-03-14

- Add ability to provide app run on root path

## 2.7.3 - 2022-01-18

- Drop ruby 2.x support (3.0.0 is a minimal version)

## 2.7.0 - 2021-03-24

- Add ability to skip setting up health endpoint on root path with `health_on_root_path` option.

## 2.6.1 - 2021-01-14

- Fix uninitialized `Timeout` error. The issue was fixed in https://github.com/rmosolgo/graphql-ruby/commit/56abba472dbb48a1f8445d41f928bea72b5148e9, but new version has not yet been relased.

## 2.6.0 - 2021-01-14

- Add ability to re-raise exception (`re_raise_exceptions` option)

## 2.5.1 - 2020-11-19

- respond with http status `400` when UTF null byte is passed as a part of the input

## 2.5.0 - 2020-11-18

- make `log_exception_backtrace` false by default and allow to be controlled by `RACK_GRAPHQL_LOG_EXCEPTION_BACKTRACE` env var

## 2.4.0 - 2020-09-39

- Use `http_status` from `ExecutionError` for http response

## 2.3.0 - 2020-09-39

- Add `error_status_code_map` option to `RackGraphql::Application`.

  `error_status_code_map` allows for return custom http code when specific errors are raised.

## 2.2.1 - 2020-09-14

- Rename `source_app` to `app_name` in error payload.

## 2.2.0 - 2020-09-14

- Add `source_app` to error payload.

## 2.1.0 - 2020-09-14

- Add `log_exception_backtrace` option to `RackGraphql::Application`

## 2.0.0 - 2020-09-14

- Catch all exceptions raised by the app respond with 500 status codea and json content type
- Add ability to not log exception backtrace with `RackGraphql.log_exception_backtrace = false`
