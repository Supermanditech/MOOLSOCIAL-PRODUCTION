# Redmi V6 isolated build prerequisite

Founder authorized a separate Cursor Redmi worktree and one review APK from V6. No permission from Desktop Codex is being requested.

Worktree: C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913
Branch: work/cursor-ui/redmi-v6-audit-20260913
HEAD: da4d266f97b4081f55bd98f1e9522f25bc8ee05f
Git worktree creation completed with exit 0. Readback showed zero tracked changes and zero untracked files. Original worktrees were not edited.

Unmodified command: scripts/check-approved-ui-locks.ps1 in the new worktree.
Execution session 80019 completed with exit 1.
Exact error at line 153: Approved UI Accessibility projection requires its exact isolated native owner.

Cause: Get-CursorAccessibilityNativeProjection recognizes the historical Cursor root and the exact combined correction/V6 integration root-and-branch pairs. This new founder-authorized root is outside those literals, despite retaining the exact V6 source. This is a tooling identity blocker, not evidence of an application defect.

No checker, ownership policy, application, test, dependency or reference changed. No APK build/install or device data change occurred. Existing prohibition on changing checker exceptions remains applicable. Safe continuation requires resolving this exact tooling identity boundary under explicit authority; no in-memory path substitution, root impersonation or skipped gate is acceptable.
