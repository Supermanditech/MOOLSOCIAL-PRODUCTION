# C25F Screen04 predecessor navigation conformance rejection

- Date: 2026-08-09
- Required-suite progress: Ride vertical passed; Screen04 stopped the remainder
- Status: registered before test migration

Eight Screen04 conformance cases retained the predecessor contract: Social local rail absent, large launcher, menu-contained subactions and menu-contained Chat. C25 requires the Social four-action rail to stay directly visible, the compact MoolSocial launcher to open a main-only menu, and Chat to remain a one-tap header action.

The other eighteen Screen04 cases passed, including content, video, Feed/Create and the full 320–430 px/100–140% matrix. The migration changes only the superseded navigation assertions and helpers; all Social business/media outcomes remain intact and the protected successor seal will be regenerated after the bounded diff.
