# Independent Redmi admission: proposed change set and validation plan

Status: proposal only. No additional repository change has been applied. The previously approved UI-lock addition remains uncommitted. This document supersedes the incomplete suggestion that adding a single path would make the independent build ready.

## Fixed identity

- Root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913
- Branch: work/cursor-ui/redmi-v6-audit-20260913
- Task: /root/cursor_redmi_v6_audit_20260913
- Execution role/lane: subagent / cursor_ui, as required by the existing lane schema. This is a tool identity; it does not require Desktop to operate the worktree or another AI agent to be spawned.
- Work ID: redmi-v6-audit-20260913
- Ticket: UAW-CURSOR-REDMI-V6-AUDIT-20260913
- Baseline: da4d266f97b4081f55bd98f1e9522f25bc8ee05f
- Existing reviewed source argument: 10fb79b4469203371edf888e7d4b8aacb3546581 (unchanged; V6 application tree equality must be independently proved).

## Exact repository change scope

1. scripts/check-approved-ui-locks.ps1: only the existing approved 26-line addition, already present. No further change proposed.
2. scripts/check-buy-protected-baseline.ps1: exact new root/branch entry and additional V6 identity checks below. No changes to its source allowlist or excluded content.
3. config/codex-subagent-coordination-policy.json: one exact continuation and active task claim; transfer only overlapping admission-file claims inside this new worktree. Existing claims in other worktrees remain untouched. No global lane permission changes.
4. scripts/check-codex-subagent-coordination-policy.ps1: mechanically recognize that one continuation and its literal owner list. Preserve every existing check. Details below.
5. docs/quality/UAW-CURSOR-REDMI-V6-AUDIT-20260913.md: record founder authority, exact identities, source invariants, original failures, proposed/actual validations and audit-only scope. This is task evidence, not a new policy framework.

No change proposed to backend/data-egress scanners, brand checker, Windows compatibility checker, build wrapper, regression registry, app code, tests, dependencies or images. The backend/data-egress/brand/Windows wrappers already forward the integrated-review argument to the protected-Buy verifier. They should be invoked with the existing source argument, not edited.

## Protected-Buy diff

In Test-IntegratedStoreBuyReviewSource, add exactly this switch arm:

```diff
+    'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913' {
+      'work/cursor-ui/redmi-v6-audit-20260913'
+    }
```

After existing currentBranch equality validation, add:

```diff
+  if ($expectedBranch -ceq 'work/cursor-ui/redmi-v6-audit-20260913') {
+    $redmiV6 = 'da4d266f97b4081f55bd98f1e9522f25bc8ee05f'
+    & git -C $root merge-base --is-ancestor $redmiV6 HEAD
+    if ($LASTEXITCODE -ne 0) { return $false }
+    & git -C $root diff --quiet $redmiV6 HEAD -- apps backend contracts
+    if ($LASTEXITCODE -ne 0) { return $false }
+    & git -C $root diff --quiet $redmiV6 -- apps backend contracts
+    if ($LASTEXITCODE -ne 0) { return $false }
+  }
```

All existing requirements remain: pinned reviewed source, both original ancestors, committed/working application equality, unchanged historical backend/contracts and no untracked source. Existing review exceptions remain disclosed as review-only, not production qualification.

## Continuation data addition

```json
{
  "id": "cursor_redmi_v6_audit_20260913",
  "state": "founder_authorized_2026_09_13",
  "lane": "cursor_ui",
  "role": "subagent",
  "task": "/root/cursor_redmi_v6_audit_20260913",
  "workId": "redmi-v6-audit-20260913",
  "ticketId": "UAW-CURSOR-REDMI-V6-AUDIT-20260913",
  "worktreePath": "C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913",
  "branch": "work/cursor-ui/redmi-v6-audit-20260913",
  "baselineHead": "da4d266f97b4081f55bd98f1e9522f25bc8ee05f",
  "bootstrapCommitSubject": "coordination(redmi-v6-audit-20260913): admit exact V6 Redmi audit lane",
  "bootstrapOwners": [
    "config/codex-subagent-coordination-policy.json",
    "scripts/check-codex-subagent-coordination-policy.ps1",
    "scripts/check-approved-ui-locks.ps1",
    "scripts/check-buy-protected-baseline.ps1",
    "docs/quality/UAW-CURSOR-REDMI-V6-AUDIT-20260913.md"
  ],
  "cursorIndependent": true,
  "integrationRequiredBeforeSuccessorApk": true
}
```

Keep the integration requirement true: V6 is the integrated source. If an existing runtime check interprets this as requiring another product merge after admission-only commits, report that exact rejection; do not toggle the requirement false or manufacture integration evidence.

## Exact evidence owners for this task

Under docs/quality/cursor-redmi-v6-audit-20260913/, permit only these literal files:
scope-state.json, PREBUILD.md, UAT.md, DEFECTS.md, JOURNEYS.csv, PUBLIC-DATA.csv, BLOCKERS.md, EVIDENCE.csv, HANDOFF.md, apk-regression-state.json, source-manifest.txt, uaw-cursor-redmi-v6-review-20260913-build-provenance.txt.

Admission script owners are exactly the three scripts listed above, not scripts/ generally. No app owner is granted. Raw device captures and command logs go to the already authorized external evidence root with an indexed manifest. Generated build outputs remain in existing designated locations and are never represented as tracked source edits.

The APK record is prepared after admission using actual baseline/source manifest and completed check receipts; never copy OPPO pass flags. Proposed candidate ID: UAW-CURSOR-REDMI-V6-REVIEW-20260913; profile CursorUiReview / uaw_cursor_ui_review_debug; package com.moolsocial.app.cursorreview; debug, non-promotable. Select an unused version above installed 2026091101 after checking existing reservations. Validate actual signer compatibility before installation. These are build evidence values, not a permission to alter app configuration.

## Coordination verifier change specification

- Change expected continuation count from 75 to 76, and require the added entry's complete fixed identity and exact bootstrap owners. Do not merely allow any 76th entry.
- Accept founder_authorized_2026_09_13 only for that exact entry; all older entries retain their existing accepted dates and rules.
- Add a literal task/root/branch/ticket/V6-bound owner predicate for the three admission scripts and enumerated evidence files. Use it only at existing owner existence, allowed-root and forbidden-root checks. Do not remove general scripts/ or config/ prohibitions. Reject any extra owner, wrong task/root/branch or source drift.
- Existing bootstrap-only coordination owners remain bootstrap-only. Active operational ownership does not confer general policy/registry editing. No registry count/hash is invented or changed; the actual existing binding remains required.
- Preserve bootstrap parentage, exact subject/changed-owner equality, staged-set requirements, no rewrite/force-push, clean handoff and live remote equality. Do not reuse an old task identity to make a gate pass.

These are the only proposed coordination semantics. A final executable patch must be checked against this specification before application; no additional special case is authorized by approval of this document.

## Commit and verification sequence

1. Preserve current V6 and the already approved unstaged UI-lock change. Capture exact diff and source tree hashes. Confirm no other writer/device operation.
2. Validate the proposed patch in isolated checker-unit tests, explicitly labelled mocks. Wrong root/branch/task/role/ticket/source; extra owners; missing V6/original ancestors; changed native/app/test/asset/dependency/backend bytes; untracked source; wrong bootstrap parent/subject; and incorrect registry pins must reject. Old admitted lanes must retain their behavior.
3. Apply only the reviewed owners after explicit approval. Run full actual UI-lock, protected-Buy and unchanged boundary wrappers; retain original and modified outputs. Do not convert the original 18/6/1 findings into production passes.
4. Stage the exact five bootstrap owners, run the existing coordination_bootstrap path and inspect its terminal result before committing. If the unchanged process cannot admit this exact set, stop; never commit after a failed gate. Commit with V6 as sole parent and the exact subject above. Record its new SHA separately from V6.
5. Run normal operational ownership/handoff checks with the new task identity and source equality. Prepare evidence-only build records from actual results. Run required build prerequisites, not fabricated state. Commit/push only through passing existing gates and verify fresh remote equality.
6. Build one CursorReview APK, verify artifact/signer/package/version/source and installed hash without clearing data, then perform the authorized audit. No product implementation, OPPO action or production claim.

## Approval boundary and limitations

This is a bounded change specification with literal protected-Buy diff and continuation JSON, not a tested, ready-to-apply patch for the coordination checker. Coordination edits require exact implementation and isolated validation before they can be presented as executable-qualified. No claim is made that all future build prerequisites pass. Any further required checker predicate, owner, exclusion or global rule change is outside this proposal and must be disclosed before proceeding.
