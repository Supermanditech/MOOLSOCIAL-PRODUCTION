# C30T Chat test text-match cardinality regression

## Observation

Two rewritten Chat tests failed for test-only reasons. One expected a sentence fragment as a complete `Text` value. The other required exactly one participant-name widget even though the name truthfully appeared in both the app bar and a message sender label.

## Root cause

The tests asserted incidental widget text cardinality instead of stable behavioral state.

## Permanent prevention

- Prefer stable keys for route and control ownership.
- Use `textContaining` for deliberate sentence fragments.
- When a truthful identity can appear in multiple semantic locations, require one or more matches and pair that check with an exact screen key or subtitle.
