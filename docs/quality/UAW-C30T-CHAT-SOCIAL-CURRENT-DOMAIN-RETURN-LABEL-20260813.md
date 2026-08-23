# C30T Chat to Social current-domain return label

- Date: 2026-08-13
- Device: OPPO CPH2375, serial `2b3e0f71`
- Installed artifact: Google Play Internal Testing `1.0.0-r60.44 (2026081244)`
- Scope: navigation-only comprehensive journey inventory

Chat is a nested route inside the Social domain. After the exact main menu was opened, its unique Social control was labelled `Social, current domain`, not `Open Social`. The first return assertion expected the latter and stopped before a second tap.

The menu remains open on Chat. The retry must select exactly the enabled clickable `Social, current domain` node from a fresh hierarchy and then prove Social Home semantics before any Feed action.
