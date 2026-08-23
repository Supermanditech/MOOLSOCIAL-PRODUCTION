# C29N dynamic test-key source-shape gate false rejection

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1234-C29N-DYNAMIC-TEST-KEY-SOURCE-SHAPE-GATE-FALSE-REJECTION`

The next cycle was stopped by the ticket source gate before format, analysis or
tests. It required an inline `Key('social-create-moolsocial-quiz')`, while the
already passing protected test stores the exact literal in a list and builds
`Key(key)` inside its assertion loop. The gate now checks the stable literal and
retains the behavioral test as authority instead of enforcing equivalent syntax.
