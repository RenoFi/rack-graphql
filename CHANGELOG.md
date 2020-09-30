# CHANGELOG

## 2.3.0 - 2020-09-39

- Add `error_status_code_map` option to `RackGraphql::Application`. It allows for return custom http code when specific errors are raised.

## 2.2.1 - 2020-09-14

- Rename `source_app` to `app_name` in error payload.

## 2.2.0 - 2020-09-14

- Add `source_app` to error payload.

## 2.1.0 - 2020-09-14

- Add `log_exception_backtrace` option to `RackGraphql::Application`

## 2.0.0 - 2020-09-14

- Catch all exceptions raised by the app respond with 500 status codea and json content type
- Add ability to not log exception backtrace with `RackGraphql.log_exception_backtrace = false`
