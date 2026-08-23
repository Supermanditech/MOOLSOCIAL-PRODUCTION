# UAW C30T Create-draft broad-patch context mismatch — 2026-08-13

## Outcome

The first Create draft-controller implementation attempted one broad patch
across the model, State lifecycle, media actions, Quiz selection and consumer.
One recovered-media context block did not exactly match the current dirty file,
so `apply_patch` rejected the patch atomically.

No part of the implementation applied.

## Permanent prevention

For a large user-owned dirty file, patch small independently verifiable regions
using exact current context: model/widget API, State initialization, each action
group, clear behavior, consumer binding, then tests. Never rely on a broad
context patch across distant regions.
