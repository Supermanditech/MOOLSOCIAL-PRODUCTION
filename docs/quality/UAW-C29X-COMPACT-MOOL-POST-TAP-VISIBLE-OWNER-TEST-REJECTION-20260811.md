# C29X compact Mool post-tap visible-owner test rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-CHAT-GLOBAL-EDGE-AND-CONTRAST-C29X`
- Result: focused Chat suite rejected, 1 failing test

After the test key migration, the compact Mool action was found and tapped, but one journey still expected the old immediate `personal-mool-root-v2` owner. The shared compact launcher uses its connected-switcher interaction contract, so the post-tap assertion was not yet reconciled. The retry inspects the exact production callback and connected-switcher visible-owner keys before changing either source or test. No build, install, device action, deployment or external write occurred.
