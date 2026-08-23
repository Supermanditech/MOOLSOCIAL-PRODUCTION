# C17C Social and Buy clear-glass conformance completion

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SOCIAL-BUY-CLEAR-GLASS-CONFORMANCE-FIX2-C17C`

Social and Buy now consume the one C17B renderer as two professional
four-action families. Social's stale 44px wrapper is bound to the shared 52px
rail token and uses the media tone; Buy uses the light tone and the deep
accessible Buy accent. Selected tinting preserves the exact .58/.52 base glass
alpha, so selection does not increase background blocking.

Qualification passed:

- C17C static family gate, including the C17B shared-owner gate;
- 12 focused C17B/Social/Buy checks;
- 6 independently rerun Social C16B, Buy C10C and C17C navigation checks;
- focused Flutter analysis with no issues;
- exact eight real labels, 48px targets, selected/available semantics,
  provider SVG attribution, one-tap Buy/Social transitions and transparent
  family shell.

All rejected attempts and corrections remain registered through regression
entry 356. No APK was built or installed; OPPO r60.16 remains untouched.
