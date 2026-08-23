# REG-20260816-2607 — C33N source-gate completion result was not retained

Date: 2026-08-16 IST

The first corrected C33N source-gate process ran to completion, but the
orchestration emitted only the initially empty output and did not retain the
returned session identifier or final exit status. A sanitized process check
later proved the process had ended, but it cannot prove that the gate passed.
The run is therefore not counted.

The correction is orchestration-only: retain the session identifier returned
by a long-running command, poll that exact session to a terminal exit result,
and preserve its sanitized output and exit code before counting a gate. Never
start a duplicate while the retained session remains active. No runtime,
build, hidden-input, Play, OPPO, provider, device or external action occurred.
