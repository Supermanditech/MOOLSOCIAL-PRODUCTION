# C29O empty compile-time source-fixture test rejection

Date: 2026-08-11

The newly authored C29O source-absence test initially read a
`String.fromEnvironment` value whose default was empty. No test was run, but
the assertion could not have inspected the actual production owner and was
therefore rejected before qualification.

Permanent prevention: source-shape tests use the repository's established
package-local literal `File(...).readAsStringSync()` owner or an explicitly
provided non-empty fixture whose provenance is asserted. An empty environment
default is never source evidence.
