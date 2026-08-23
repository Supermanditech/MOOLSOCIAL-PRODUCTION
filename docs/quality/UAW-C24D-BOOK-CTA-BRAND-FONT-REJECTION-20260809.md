# C24D booking CTA brand-font rejection — 2026-08-09

The first OPPO-class widget capture rendered the fixed booking CTA label as
white Ahem glyph blocks. The local `FilledButton.styleFrom(textStyle:)`
specified size and weight but dropped the Inter family supplied by the global
button theme.

The production correction explicitly retains `fontFamily: 'Inter'` in that
local style. The regenerated capture must show the complete vehicle and fare
label legibly; the functional 48px action and truthful semantics remain
unchanged.
