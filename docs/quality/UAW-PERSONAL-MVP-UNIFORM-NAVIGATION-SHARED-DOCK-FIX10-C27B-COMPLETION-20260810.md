# C27B completion — uniform shared destination dock

C27B is complete.

- One shared 58px neutral clear canvas now owns the personal destination dock.
- `railHeight` aliases the same 58px token, removing Social's predecessor 52px
  constraint without editing protected Social feature content.
- Mool, family context and local actions reuse one 22px icon / 10.5px Inter
  icon-label owner.
- Automatic label scale-down is removed; truthful long sparse labels may use
  two fixed-size lines.
- Two- and three-action clusters are compact and leading-connected; four-action
  families adapt at 320px without scrolling.
- Only a selected local destination renders the resting indicator; Mool renders
  it only while the switcher is open.
- The dock preserves persistent bottom view padding and nominal 44px-or-larger
  host targets.
- The unused disclosure animation, overlay, anchor keys and 20-frame
  measurement loop are removed from the live destination shell.
- Focused analyzer: clean.
- Focused successor/predecessor suite: 32 tests passed.
- C27B, C26B, C26C, regression-memory and MVP scope gates passed.

OPPO-exported semantic bounds and first-root Travel/Work Mool paint remain open
for the later device child; no build or install occurred in C27B.
