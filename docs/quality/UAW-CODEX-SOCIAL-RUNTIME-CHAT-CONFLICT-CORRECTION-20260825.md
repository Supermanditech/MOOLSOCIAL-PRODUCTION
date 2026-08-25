# Social runtime and contextual Chat conflict correction

Ticket: `UAW-CODEX-SOCIAL-RUNTIME-CHAT-CONFLICT-CORRECTION-20260825`

This is a narrow primary-owned integration-repair ticket authorized by the
founder after the independent Codex and Cursor lanes closed. It preserves these
immutable source tips:

- Codex runtime: `922c2a9d776f7de96ba9ec9a7ca6175d1cc2fce9`
- Cursor contextual Chat: `00ce93552091ee51739266c0a8fbe6d207d9f695`

The first local integration attempt is retained unchanged and unpushed at
`792ad84b2a033a489add056b3e21620b142e9dcc`. It is not a release candidate.

The correction may create exactly one two-parent merge. Its first-parent
history must descend from the sealed Codex tip and its second parent must be the
sealed Cursor tip. Manual resolution is limited to the nine conflict owners
recorded in machine policy. No ordinary direct product commit, rebase, squash,
cherry-pick, force push, APK, install, deployment or promotion is authorized.

The ticket loop is:

`PENDING -> IMPLEMENTED -> TESTED -> RUNTIME_PROVEN -> AUDITED -> CLOSED`

Any observed gap becomes a child atomic ticket and must be fixed, retested and
re-audited before closure. Runtime proof in this source round means focused and
combined Flutter execution plus the applicable non-building preflight. Final
integrated APK/OPPO proof remains separately authorized and may reopen a causal
ticket.

Closure requires both source tips and their remote branches to remain exact,
all conflict and automatically merged owners to pass focused and broad
regressions, approved UI locks to pass, a clean worktree, secret-safe evidence,
an independent audit, and exact remote readback of the repair tip.
