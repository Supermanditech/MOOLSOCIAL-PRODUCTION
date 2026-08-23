# C26F Care and Work navigation conformance preselection

Classification: `mvp_required`

## Customer outcome

Care and Work receive the same transparent, background-independent rail. Care retains Doctor, Medicine and Salon; Work retains Earn Today and Workspace. Medicine remains under Care while reusing its existing Buy commerce owner, correcting the r60.24 inherited-theme contrast defect.

## Scope, reuse and duplication decision

- Runtime implementation disposition: shared configuration already complete; no runtime mutation authorized.
- Existing owners: `BookPageScaffold`, `BookSession`, Buy Medicine route/session, `WorkPageScaffold`, `WorkSession` and `MoolDestinationNavigationV2`.
- No new screen, route, subaction, session, state or backend owner.

## Focused proof

- Care: root, Doctor, Medicine and Salon remain direct.
- Work: root, Earn Today and Workspace remain direct.
- Medicine renders the Care rail independently of Buy's destination background.
- Doctor, Medicine and Salon use uniform neutral navigation contrast.
- First Back closes Mool while preserving exact Care or Work state.

Build, installation and external writes remain unauthorized in C26F.
