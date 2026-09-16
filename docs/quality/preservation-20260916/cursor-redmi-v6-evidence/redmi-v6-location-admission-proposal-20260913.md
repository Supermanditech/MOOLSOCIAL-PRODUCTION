# Proposed Redmi V6 build-location admission — not applied

Only proposed repository owner: scripts/check-approved-ui-locks.ps1.
Preserved baseline: da4d266f97b4081f55bd98f1e9522f25bc8ee05f.
Original failure remains recorded in redmi-v6-audit-build-prerequisite-20260913.md.

## Proposed diff

```diff
@@ Get-CursorAccessibilityNativeProjection: combinedBranch switch
     'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-INTEGRATION-store-buy-final-v6-20260912' {
       'integration/moolsocial/store-buy-final-v6-20260912'
     }
+    'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913' {
+      'work/cursor-ui/redmi-v6-audit-20260913'
+    }
     default { $null }
@@ after existing exact branch validation, before existing ancestry checks
+  if ($requiredBranch -ceq 'work/cursor-ui/redmi-v6-audit-20260913') {
+    $redmiBaseline = 'da4d266f97b4081f55bd98f1e9522f25bc8ee05f'
+    & git -C $root merge-base --is-ancestor $redmiBaseline HEAD
+    if ($LASTEXITCODE -ne 0) {
+      throw 'Redmi audit requires the preserved V6 ancestor.'
+    }
+    $redmiBoundaries = @(
+      'apps', 'backend', 'contracts', 'packages',
+      'package.json', 'package-lock.json', 'pubspec.yaml', 'pubspec.lock'
+    )
+    & git -C $root diff --quiet $redmiBaseline HEAD -- @redmiBoundaries
+    if ($LASTEXITCODE -ne 0) {
+      throw 'Redmi audit committed source differs from V6.'
+    }
+    & git -C $root diff --quiet $redmiBaseline -- @redmiBoundaries
+    if ($LASTEXITCODE -ne 0) {
+      throw 'Redmi audit working source differs from V6.'
+    }
+    $redmiUntracked = @(& git -C $root ls-files --others --exclude-standard -- @redmiBoundaries)
+    if ($LASTEXITCODE -ne 0 -or $redmiUntracked.Count -ne 0) {
+      throw 'Redmi audit has untracked source.'
+    }
+  }
```

The existing native whole-source, accessibility-block and projected-source hashes remain untouched. Existing original-source ancestry checks, assertions and all other checks remain untouched. This proposal does not add security/egress exclusions. An admission commit may advance HEAD while source-tree equality to V6 remains mandatory; report both SHAs, never claim HEAD is unchanged.

## Validation plan after explicit approval

1. Inspect the exact single-owner diff; parse PowerShell without executing a build.
2. Exercise the checker logic with the selected root/branch and exact V6 source; reject wrong root, wrong branch, missing V6/original ancestor, changed native bytes, changed committed or working app/test/asset/dependency bytes, and untracked source. Test fixtures must be labelled as checker tests, not real candidate qualification. Do not alter the real worktree's source to create negative cases.
3. Run the full unmodified-entry-point UI-lock check in the actual new worktree, preserving the original failing receipt and new result separately. A focused helper pass alone is insufficient.
4. Before a commit, satisfy the existing ownership and Git gates. Do not self-expand the claim or weaken any gate. If existing ownership admission is unavailable, stop with the exact boundary.
5. Record the admission commit and prove all application/test/native/asset/dependency trees still match V6. No APK until all other original build prerequisites pass.

## Additional unchanged prerequisite discovered

scripts/check-buy-protected-baseline.ps1, Test-IntegratedReviewSource (around lines 346–358), accepts only the correction and V6 integration root/branch pairs, with source 10fb79b4469203371edf888e7d4b8aacb3546581. It returns false for the new independent Redmi root. This is a source-inspected restriction, not a newly executed failure. Fixing the UI-lock path alone will not make this integrated-review prerequisite portable. No change to this second checker is proposed or applied here. Its effect on the existing build invocation must be resolved explicitly before expanding this proposal.

No application, checker, policy, reference or dependency was edited to prepare this document. No build or device action occurred. Founder approval is requested only for the concrete UI-lock proposal above; it is not blanket authorization for subsequent checker or ownership changes.
