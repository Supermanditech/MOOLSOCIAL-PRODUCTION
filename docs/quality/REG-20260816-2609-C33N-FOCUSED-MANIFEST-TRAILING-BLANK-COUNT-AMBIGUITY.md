# REG-20260816-2609 — C33N focused manifest had a trailing blank count ambiguity

Date: 2026-08-16 IST

The C33N focused manifest contained the intended 73 test paths plus one blank
line. The authoritative runner filters blank lines and would execute 73 files,
but a raw line count reported 74. No test cycle was started or counted with
that ambiguous manifest.

The correction is to remove the blank record before the candidate source seal
and require both raw nonblank count and runner count to equal 73. No product
runtime, build, Play, OPPO, device, secret or external state changed.
