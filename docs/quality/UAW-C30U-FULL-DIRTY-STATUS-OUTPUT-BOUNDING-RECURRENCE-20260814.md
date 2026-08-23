# C30U full dirty-status output-bounding recurrence

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Incident

After laptop restart reconciliation, `git status --short --branch` was grouped
with the scalar branch and HEAD reads. The repository contains a very large
founder-owned dirty tree, so the status body exceeded the task output boundary
and was truncated. The branch and HEAD scalars were visible, but the rendered
status body is rejected as complete dirty-ownership evidence.

## Root cause

The resume check repeated an unbounded full-status display despite the durable
rule requiring branch, HEAD and dirty ownership to be reconciled independently
and requiring untracked enumeration to remain disabled.

## Prevention

Never print or fully enumerate this preserved dirty tree during routine release
reconciliation. Read branch and HEAD independently, then use an in-memory Git
process with long-path support, `--untracked-files=no`, separate stdout/stderr,
zero exit and empty stderr. Report only deterministic tracked-record count and
SHA-256. Preserve every tracked and untracked owner in place.

## Release effect

No file was removed or overwritten. No AAB, upload, Play activation,
installation or OPPO mutation occurred. C30U build, upload and install counts
remain zero and build authority remains closed.

## Bounded reconciliation result

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Tracked dirty records: `449`
- Deterministic tracked-status SHA-256:
  `7ED5E62DA7827098D0CFBD2DB163B0DE9F5FF8EA77BEA7B9D610C90D43C52F0F`
- Git exit: `0`
- Stderr length: `0`
- Untracked enumeration: `disabled`; every existing untracked owner remains
  preserved in place.
