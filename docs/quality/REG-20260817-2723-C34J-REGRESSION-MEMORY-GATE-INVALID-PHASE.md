# REG2723 — C34J regression-memory gate invalid phase

Date: 2026-08-17 IST

The C34J pre-seal verification invoked the regression-memory checker with
`-Phase release`. Its declared validation set is `general`, `implementation`,
`build`, and `device`, so parameter binding rejected the invocation before the
checker body ran. No candidate transition, build, source cycle, external write,
or evidence authority was consumed.

The release-candidate preparation uses the declared `build` phase. Future
invocations must inspect the checker parameter contract before supplying an
enumerated phase and must not infer phase names from the surrounding workflow.
