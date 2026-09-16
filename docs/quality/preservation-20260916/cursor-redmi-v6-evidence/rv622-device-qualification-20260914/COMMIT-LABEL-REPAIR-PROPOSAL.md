# Proposed disposition of one historical evidence commit

Status: prepared for founder decision; not applied to repository checks.

The current handoff gate rejects commit `448d4a2c7c10ee195e711e49aa4cc69a593ff37b` solely for its subject prefix. The agent used `docs(redmi)` instead of the required `ui(redmi-v6-audit-20260913)`. The commit is pushed and must remain preserved. A later correctly named commit cannot change the old subject, and rewriting history is excluded.

Proposed approval: admit this one historical commit-label exception after verifying every binding below. This is an explicit exception to the label rule, not a claim that the original label complied. Do not broaden the accepted subject pattern for future commits, skip the commit-history scan, or suppress another gate failure.

| Binding | Required value |
| --- | --- |
| Repository | C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913 |
| Branch | work/cursor-ui/redmi-v6-audit-20260913 |
| Task | /root/cursor_redmi_v6_audit_20260913 |
| Lane / work ID | cursor_ui / redmi-v6-audit-20260913 |
| Ticket | UAW-CURSOR-REDMI-V6-AUDIT-20260913 |
| Historical commit | 448d4a2c7c10ee195e711e49aa4cc69a593ff37b |
| Sole parent | d0dfea24e52c3c60c41d0cd01fcdcd2badfbcd6c |
| Exact historical subject | docs(redmi): close D005 persistence with r66.22 device evidence |
| apps tree, commit and parent | e37147034016157ab241e26f0c8be091d4561a9c |

The changed owner set must be exactly these four files under `docs/quality/cursor-redmi-v6-audit-20260913/`, with these committed Git blob IDs:

| Owner | Blob |
| --- | --- |
| DEFECTS.md | dd866dd5ee2f4e7637236095563bb15f568680ce |
| EVIDENCE.csv | 18c272611cb3ffd9e815cbfd476eef073778b8cd |
| UAT.md | d687685148c71995378459ec909e825c72b97050 |
| scope-state.json | 17ae58a35b227394f23d8afb65ab8153f00d6137 |

Any other commit, parent, label, owner, blob, application tree, lane, branch, task or ticket must fail the exception. All ordinary commits still require their existing prefix. The current source pins, protected-source checks, registry generation, owner claims, secret/backend/egress checks, build gates and physical Redmi acceptance requirements remain mandatory. The existing checker-preservation check must continue to verify unchanged code outside the explicitly admitted repair; its digest must not simply be replaced to hide edits.

Before applying: verify these Git bindings against the current repository and review the narrowly scoped checker patch. After applying: exercise exact-positive and altered-identity/payload negative cases; run the real coordination handoff gate and retain any independent failure. This proposal does not itself pass that gate or authorize an APK.

D014 source correction is separately committed at `4221158fead95a89047e3408aaeb11c9a12dd135`, with336 local Buy screen tests,21 overlapping D014 cases, reviewed Flutter captures and clean analysis. Device count remains21/22 because the corrected source has not yet been built and replayed on Redmi. Combined regression, source/build qualification and that replay remain required.

Suggested founder decision: "Approve the single historical commit-label exception for 448d4a2c exactly as bound in this proposal. Preserve history and all other checks; continue D014 qualification."
