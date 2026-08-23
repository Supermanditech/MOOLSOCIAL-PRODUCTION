# C20C first focused-test press-highlight timing rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SHARED-NEUTRAL-BRAND-GLASS-CONTROL-FIX3-C20C`

The first C20C focused invocation passed seven of eight cases. It qualified the
two permitted Mool identity selection signals, 2/3/4-action geometry, 48px
targets, 16px radius, 13px/700 labels, 20px icons, neutral selected fills,
representative light/media contrast, provider optical sizing and immediate
reduced motion.

The press-state case started a touch and sampled at `80ms`. Flutter's touch
InkWell intentionally delays touch highlight until after the gesture timeout,
so `_pressed` had not yet changed and the neutral glass alpha remained at its
inactive value `0.5607843137254902`. This was a test timing error, not a family-
colour or opacity regression. No build, install or OPPO mutation occurred.

The press test must sample after the touch highlight delay but within the
finite 160ms state transition, then prove the RGB remains neutral, alpha rises,
scale reaches `0.985`, release opens exactly once and reduced motion remains
immediate.
