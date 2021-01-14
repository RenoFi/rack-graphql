# CHANGELOG

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
