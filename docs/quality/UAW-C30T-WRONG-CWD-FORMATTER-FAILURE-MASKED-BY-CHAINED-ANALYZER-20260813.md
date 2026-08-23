# C30T wrong-CWD formatter failure masked by chained analyzer

- Regression: `REG-20260813-1965-C30T-WRONG-CWD-FORMATTER-FAILURE-MASKED-BY-CHAINED-ANALYZER`
- Date: 2026-08-13
- Scope: Comment/Reply source qualification.

## Incident

From the `apps/mobile` workdir, the formatter was given an `apps/mobile/...`
path and reported it missing. A later analyzer in the same process exited zero,
masking the first tool's failure. The combined result was rejected.

## Required prevention

Run formatter and analyzer in separate processes with paths relative to the
explicit workdir. Admit only each tool's own exit and completion output.

This record creates no build, upload, install, deployment or device authority.
