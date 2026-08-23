# C30T Google Play Open nested-clickable ancestor rejection

- Date: 2026-08-13
- Device: OPPO CPH2375, serial `2b3e0f71`
- Installed artifact: Google Play Internal Testing `1.0.0-r60.44 (2026081244)`
- Scope: recovery to the installed app without install/update/data mutation

The exact Google Play app-detail screen contains one `com.moolsocial.app (unreviewed)` title. Its Open button is represented by two labels at `[499,440][570,480]`: one `content-desc=Open` view and one `text=Open` TextView. Neither label is clickable. Both resolve upward to the same enabled clickable ancestor at `[372,412][696,508]`.

The first recovery assertion required a directly clickable label and therefore stopped before any tap. Recovery may proceed only from a fresh hierarchy that reproduces the unique app title, both same-bounds Open labels, and exactly one shared enabled clickable ancestor. Only that ancestor centre may be tapped once.
