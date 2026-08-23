# C28C host-cycle launcher timeout rejection

- Date: 2026-08-10
- Phase: qualifying host cycle 1 launch
- Passed before termination: the initial C28C, C28B, C27B, C27C, C27D,
  C26B, C26C, C26D, C26E, C26F, C25A and placement gates
- Rejection: the shell launcher was configured with a one-second command
  timeout and terminated the qualifier during the initial gate set.
- Qualification effect: cycle 1 did not reach formatting, analysis, tests,
  post-gates or evidence creation and therefore did not count.
- Runtime/build/install effect: none; r60.26 remained installed and no APK
  authority opened.
- Root cause: a short timeout was used in an attempt to obtain a resumable tool
  cell, but this shell runner treated it as a hard process deadline.
- Prevention: launch complete host cycles with a sufficient command timeout;
  use yielded execution cells only when the runner returns one naturally, and
  never treat a prematurely terminated cycle as qualifying evidence.
