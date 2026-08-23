# REG2946 — Founder-visible MoolSocial but activity-top mismatch

## Observed event

After the founder confirmed Gmail closed and MoolSocial visibly open, the guarded device command selected the first `ACTIVITY` row from `dumpsys activity top` and did not find `com.moolsocial.app`. It stopped before UI hierarchy capture, provider tap, account/private inspection, or external action.

## Root cause boundary

Either the app was not the resumed foreground activity at the instant queried, or selecting the first generic `ACTIVITY` row is not a reliable top-resumed-package method on this OPPO/Android build.

## Mandatory prevention

After registration, compare only sanitized package/component facts from two independent sources: `topResumedActivity`/`mResumedActivity` and WindowManager `mCurrentFocus`/`mFocusedApp`. Do not inspect UI unless both resolve to MoolSocial. Never select the first generic `ACTIVITY` row as sole foreground authority.
