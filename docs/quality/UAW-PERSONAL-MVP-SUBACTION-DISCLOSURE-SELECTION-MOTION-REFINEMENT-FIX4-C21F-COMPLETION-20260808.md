# C21F disclosure, selection and motion refinement completion — 2026-08-08

C21F is complete on host with build and install closed. The existing selected global main-action control remains the only disclosure interaction owner and measures 62×48 px in the focused harness. Its selected state now contains a visible 18 px circular optical show/hide badge without creating a second tap target.

All six families default expanded. Retapping the selected main action hides and restores only that family, with truthful `Hide ... options` and `Show ... options` semantics. Collapsed state is session-only and resets recoverably. The family connector is non-interactive and non-semantic at 1.25 px, maximum 24% opacity and a 1.5 px terminal dot. Disclosure/selection transition is 160 ms, connector selection transition is 200 ms, and reduced motion settles immediately.

Evidence:

- focused disclosure/overflow suite: 10/10 passed;
- motion, Back, global Mool/Chat and shell continuity suite: 21/21 passed cumulatively;
- C21B–C21F sequential gates and C21 placement gate passed;
- MVP scope/delivery lock, approved UI locks, brand integrity, user-facing copy, all 154 interaction routes, static analysis and permanent regression memory passed;
- no APK was built or installed and checksum-matched installed r60.19 remains preserved.

C21G is the next eligible ticket and must separately prove a structural predecessor/successor optical delta and two consecutive unchanged-source host cycles before any successor APK authorization can open.
