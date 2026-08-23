# REG2937 — C34H device memory-gate phase-name guess

## Observed event

Before any post-REG2936 device diagnosis, the primary invoked the regression-memory gate with guessed phase `testing`. The gate rejected it because its exact ValidateSet is `general, implementation, build, device`.

## Impact

- The memory gate did not run.
- No device query, UI inspection, provider/account/private action, edit, retry, build, install, upload, or external write followed.

## Root cause

The phase parameter was inferred from the task description rather than read from the gate's exact interface/help or retained known command.

## Mandatory prevention

Use exact `-Phase device -BuildMode none` for read-only OPPO acceptance diagnostics; never guess gate enum values. A rejected memory gate blocks all later device commands until registered and rerun successfully.
