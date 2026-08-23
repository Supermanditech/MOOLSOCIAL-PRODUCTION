# C30Y post-FIX1 Hosting eight-pass evidence not retained

- Incident: `REG-20260814-2182-AAB-C30Y-POST-FIX1-HOSTING-EIGHT-PASS-EVIDENCE-NOT-RETAINED`
- Affected summaries: `c30y-post-fix1-cycle-01-summary.json`, `c30y-post-fix1-cycle-02-summary.json`

Each superseded post-FIX1 summary records eight Hosting tests and eight passes but contains no Hosting log path. The only retained Hosting log under the exact C30X evidence root reports seven tests and seven passes, so it cannot support the later eight-pass claims. The summaries therefore cannot be reused as post-FIX2 qualification evidence.

No Hosting test has been retried. Before qualification continues, an MVP-scoped successor repair ticket must require one unique repository-contained Hosting log per cycle and exact log-to-summary parsing of `tests=8`, `pass=8`, and `fail=0`. Fresh post-repair cycles must retain their own eight-test outputs and cannot reuse the obsolete seven-test log.

## Resolution

Two fresh post-FIX4 attempt-02 cycles each retained a complete,
overwrite-protected Hosting build/test log and exact zero exit file. Each log
reports exactly `tests 8`, `pass 8`, and `fail 0`; the cycle-owned summaries
report the same scalars. The evidence-binding gate accepted each summary under
PowerShell 7 and Windows PowerShell against the same current 1,132-file source
manifest, with release actions `0/0/0`.

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix4-cycle-01-attempt-02-summary.json`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix4-cycle-02-attempt-02-summary.json`
