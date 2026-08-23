# C29W full dirty-status output truncation recurrence

- Date: 2026-08-11
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Result: broad status render rejected

The resumed reconciliation printed the repository's full large dirty tree and the transported output was truncated. The truncated render is not accepted as a complete dirty-tree inventory. Branch and HEAD scalar evidence remain valid; subsequent checks count status records and inspect only exact ticket-owned paths and bounded unexpected-path projections. No existing tracked, modified or untracked file was removed or overwritten.
