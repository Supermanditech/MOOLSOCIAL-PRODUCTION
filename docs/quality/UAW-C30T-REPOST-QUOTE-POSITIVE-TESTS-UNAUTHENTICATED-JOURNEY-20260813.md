# C30T Repost and quote positive tests used unauthenticated Journey

- Regression: `REG-20260813-1958-C30T-REPOST-QUOTE-POSITIVE-TESTS-USED-UNAUTHENTICATED-JOURNEY`
- Date: 2026-08-13
- Scope: focused Flutter test fixtures.

## Incident

Two positive Social action tests assigned an email string but did not establish
authoritative authenticated Journey state. Runtime correctly opened sign-in,
so the mutation and composer expectations failed.

## Required prevention

Authenticated positive tests use and start an explicit authenticated Journey
snapshot, then assert `isAuthenticated` before pumping actions. Guest gate
coverage remains separate.

This record creates no build, upload, install, deployment or device authority.
