# C22H unreturned-batch progress-report rejection

- Date: 2026-08-09
- Scope: device evidence reporting

## Rejection

A progress message stated that Social Create and Eat Order Food were stable
before the running cell returned. The cell later showed Create rejected and
therefore Eat had not run. The claim was inaccurate and is not evidence.

## Prevention

For running sequential batches, report only explicit pass lines already
returned by the cell. Treat every later step as pending until the command
completes and emits its own success result.
