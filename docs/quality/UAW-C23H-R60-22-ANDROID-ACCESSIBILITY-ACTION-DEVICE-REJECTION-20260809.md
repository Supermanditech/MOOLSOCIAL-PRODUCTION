# C23H r60.22 Android accessibility-action device rejection

Date: 2026-08-09

State: `material_device_gate_rejected_successor_required`

Candidate r60.22 is correctly installed on OPPO CPH2375 with local, live and
pulled-base SHA-256 identity
`778C9338DAFDEC3693337D54410946C75F9B6B1BB5977D822DF2CF7E38D9D850`.
The first Social frame shows one centered Mool launcher and no persistent
rails. A physical tap on the launcher transitioned to the intended Home in one
action and unique `16-current-ready` and `17-home-initial` PNG/XML evidence was
preserved.

The Android accessibility tree rejects the candidate:

- `Open Mool Home` is class `android.widget.Button` but `clickable=false`.
- Home `Open Chat`, all six family controls and all 17 direct subactions are
  emitted as buttons with `clickable=false`.
- Standard app controls such as `Open notifications` are `clickable=true` in
  the same installed frame, proving this is not a global UIAutomator failure.
- The shared native root cause is an outer `Semantics(button: true,
  excludeSemantics: true)` that omits `onTap` while excluding the nested
  InkWell action. The affected owners are `_MoolHomeLauncher`, the Home Chat
  control and `_MoolHomeHubButton`.

This is material because TalkBack/accessibility activation cannot be proven and
the only way to continue automation would be a coordinate-only bypass. Device
qualification stopped after the first Home transition. No second build,
install, uninstall, data clear, downgrade or later family/subaction tap was
performed.

Successor acceptance must expose `SemanticsAction.tap` from the outer semantic
owner (or retain the nested InkWell action), strengthen the existing C23C,
C23B and C23F accessibility tests for the launcher, Chat, six families and 17
subactions, and prove `clickable=true` plus one physical tap on OPPO before a
full matrix can resume. r60.22 and all evidence remain immutable and installed
for audit until a separately gated successor is authorized.
