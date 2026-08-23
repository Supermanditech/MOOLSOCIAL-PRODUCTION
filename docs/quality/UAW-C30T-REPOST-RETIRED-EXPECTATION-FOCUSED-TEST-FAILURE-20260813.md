# C30T Repost retired-expectation focused-test failure

- Regression: `REG-20260813-1956-C30T-REPOST-RETIRED-EXPECTATION-FOCUSED-TEST-FAILURE`
- Date: 2026-08-13
- Scope: focused Flutter testing only.

## Incident

The focused suite was run even though its inspected source still asserted that
Repost was unavailable. The new server-backed interaction correctly used the
shared offline guard, so that obsolete assertion failed.

## Required prevention

An intentionally retired behavior is removed from the exact authoritative test
and replaced with successor positive and negative coverage before the first
focused test run.

This record creates no build, upload, install, deployment or device authority.
