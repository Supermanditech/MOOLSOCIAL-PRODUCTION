# C30T Chat test text-cardinality recurrence

## Observation

After one duplicated participant-name expectation was corrected, the same bounded test still required exactly one `Order Support` widget. That identity also appeared truthfully in the app bar and the message sender label.

## Root cause

The first repair addressed only the reported line instead of auditing the complete bounded test for the established assertion-pattern defect.

## Permanent prevention

- When a failure proves an assertion-pattern class, search the whole bounded test for all equivalent matchers.
- Correct every equivalent assertion before retrying.
- Pair identity-copy checks with stable screen or route keys rather than relying on single-widget text cardinality.
