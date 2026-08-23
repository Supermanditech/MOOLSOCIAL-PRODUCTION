# REG2662 — C34D sealed cycle runner stale source-manifest registry path

Date: 2026-08-16 IST

Candidate: `UAW-C34D-R60-68-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE`, `1.0.0-r60.68` / `2026081368`.

## Observed defect

After the C34D 1,291-file source manifest was sealed and the cycles-zero source gate passed in PowerShell 7 and Windows PowerShell, exact readback before cycle 1 proved the sealed source-cycle runner still declared:

`source-manifest-c34d-registry-2630.txt`

The candidate state, aggregate and retained source manifest were instead bound to registry 2,632 and:

`source-manifest-c34d-registry-2632.txt`

No source cycle was started. No hidden input, wrapper, Flutter build, AAB, Play write or OPPO mutation occurred. Counts remain `0/0/0/0`.

## Root cause

The runner summary registry count and SHA were updated, but its separate `manifestRelative` literal was missed. The C34D gate parsed the runner and asserted lifecycle ownership, but did not compare that exact literal with `state.sourceQualification.manifestPath`.

## Permanent prevention

- Reject C34D without repairing or reusing its sealed source.
- Before sealing the exact successor, bind the runner manifest path to the final registry-numbered manifest.
- Make the successor gate assert the runner literal matches candidate state.
- Run a prerequisite-path-only runner preflight before the source seal; it must not start Flutter, backend or web tests.
- Only then seal and execute two new complete source cycles.

This evidence does not imply an app, authentication, Gradle, AAB, Play, OPPO or runtime failure.
