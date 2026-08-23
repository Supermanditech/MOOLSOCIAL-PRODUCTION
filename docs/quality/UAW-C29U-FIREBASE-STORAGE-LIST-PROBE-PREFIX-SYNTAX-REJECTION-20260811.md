# C29U Firebase Storage list-probe prefix syntax rejection

- Date: 2026-08-11
- Scope: deployed deny-all Storage rules verification
- Cloud mutation: none

The first unauthenticated list probe used `c29u-deny-probe` as its prefix. Firebase Storage rejected the request shape with HTTP 400 because a non-empty prefix must end in exactly one slash. That response is not authorization evidence.

The corrected probe uses the synthetic folder prefix `c29u-deny-probe/` and accepts only an authorization rejection as proof. No object is created by either list request.
