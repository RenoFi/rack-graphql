# CHANGELOG

## 2.2.0 - 2020-09-14

- Add `source_app` to error payload.

## 2.1.0 - 2020-09-14

- Add `log_exception_backtrace` option to `RackGraphql::Application`

## 2.0.0 - 2020-09-14

- Catch all exceptions raised by the app respond with 500 status codea and json content type
- Add ability to not log exception backtrace with `RackGraphql.log_exception_backtrace = false`
