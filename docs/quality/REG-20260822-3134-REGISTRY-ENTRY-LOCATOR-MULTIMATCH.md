# REG-20260822-3134 — registry entry locator matched twice

Date: 22 August 2026

State: registered; zero registry or cloud mutation from the failed locator

A read-only `Select-String` locator searched the regression registry for the
complete REG3128 identifier and returned more than one match because the same
identifier appears in the entry ID and its evidence path. The wrapper treated
the line-number array as a scalar and failed before returning the requested
bounded entry slice.

No registry patch, IAM binding, Data Connect deploy, schema migration,
function deploy, Hosting deploy, secret payload read, build, Play action, OPPO
action, email or SMS occurred from this failed locator.

Root cause: the locator did not bind the identifier to the exact JSON `id`
property and did not require exactly one match before range arithmetic.

Prevention: locate the exact quoted `"id"` line, normalize matches with `@(...)`,
require one scalar line number, then read one bounded range before patching.
