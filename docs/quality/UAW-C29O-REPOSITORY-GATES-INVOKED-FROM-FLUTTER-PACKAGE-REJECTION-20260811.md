# C29O repository gates invoked from Flutter package rejection

Date: 2026-08-11

A compound qualification command used `apps/mobile` as its working directory
for valid Flutter analysis/tests but also invoked `./scripts/...`. The four
repository-root policy gates were not found. PowerShell continued and the
Flutter analysis plus 38 tests passed, but the command cannot count as a gate
cycle.

Permanent prevention: repository policy/source gates run from the repository
root in one command; Flutter format/analyze/test run from `apps/mobile` in a
separate command. A final successful child command never masks earlier command
discovery errors.
