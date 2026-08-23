# C20D first focused test — Social state-isolation rejection

- Date: 2026-08-08
- Scope: C20D host test-only conformance
- Buy matrix: passed
- Reduced-motion Social/Buy case: passed
- Device/build/install impact: none; closed

## Rejection

The first Social scenario completed with Create selected. The next viewport
scenario reused the same stateful harness identity, so it did not start at
Shorts and the test's initial-selection expectation failed.

## Permanent prevention

Every responsive matrix scenario receives a unique widget identity or an
explicit unmount. Initial selected state is scenario-local and verified before
the selected-state traversal begins.
