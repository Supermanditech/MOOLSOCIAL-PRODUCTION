# UAW-CURSOR-UI-SHOP-LANDING-V2-CHILD8-BUY-GOLDEN-PATH-20260828

State: `focused_verification_passed_full_buy_cycles_pending`

Customer outcome: the full Buy regression suite can verify the existing
checkout/cart responsive references before the Shop V2 Redmi review build.

The retained diagnostic run completed with 461 passes, 28 intentional skips
and exactly two failures. Both failures initially reported non-existent
`c24f`-prefixed golden paths introduced by accepted runtime commit
`f105195ba505dcc9f25a35ab64aab104dadb47c2`. Git history contains no capture at
either prefixed path. Valid no-update runs prove both original sets are stale:
R58.8.6 differs by 83.31% at its first viewport, while R58.8.7 differs by
63.16% to 86.12% across all five viewports. Neither original set can be
substituted as current authority.

Smallest complete repair:

- preserve every original PNG byte-for-byte;
- restore both accepted `c24f` reference strings;
- generate five new R58.8.6 c24f files;
- generate five new R58.8.7 c24f files only after its unique image-settle
  helper uses the established `tester.runAsync` pattern;
- visually inspect the complete new c24f set;
- run both complete responsive capture tests without update mode through
  clean-support;
- restart two complete Buy regression cycles from zero.

Excluded: Shop/profile source changes, updates to any old protected PNG,
backend, APIs, Firebase, Android configuration, OPPO, and runtime package
changes.

Verification completed:

- R58.8.6 complete file passed without update mode: Flutter exit `0`, stderr
  `0` bytes;
- R58.8.7 complete file passed without update mode: Flutter exit `0`, stderr
  `0` bytes;
- all ten new c24f captures were visually inspected at their exact Android,
  iOS and 140% accessibility viewports;
- no Shop/profile production source, old protected PNG, backend, Firebase or
  Android owner changed.

The final authority for Shop landing fitment remains the separately required
Redmi review of the uniquely versioned CursorUiReview APK.
