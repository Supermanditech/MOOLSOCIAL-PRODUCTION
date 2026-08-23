# Post-C33D Buy unbounded runtime/test inventory output truncation

Date: 15 August 2026
Regression: `REG-20260815-2333-POST-C33D-BUY-UNBOUNDED-RUNTIME-TEST-INVENTORY-OUTPUT-TRUNCATION`

## Observation

The first read-only post-C33D Buy inventory combined an unbounded runtime and
test path listing. The tool reported that its output exceeded the available
model context and was truncated. The command made no repository, build,
device, provider or external-service mutation.

## Root cause and recovery

The discovery command did not separate counts from path disclosure or cap its
filename batches. The broad command will not be retried. Recovery is limited
to bounded read-only checks: count candidate owners first, inspect exact
non-golden filenames in small capped groups, inventory visual/golden evidence
separately and only then select current source tests using registered suite
dispositions.

## Protected boundary

This recovery does not select or authorize a Buy successor ticket and does not
change the protected Buy baseline. Build, Play, OPPO, backend, provider,
credential, email and quota actions remain held at their existing gates.
