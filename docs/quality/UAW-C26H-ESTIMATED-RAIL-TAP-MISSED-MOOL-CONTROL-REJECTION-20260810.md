# C26H estimated rail tap missed Mool control rejection

- Observed: an estimated tap at device coordinate `[55,1468]` did not activate the Mool control; the next truthful UI dump still exposed `Open MoolSocial main menu` and no open switcher.
- Root cause: the device workflow estimated a coordinate from the rendered rail rather than deriving the exact current clickable semantic bounds from the OPPO hierarchy.
- Classification: evidence-driving input defect, not a proven Flutter navigation defect. The rejected switcher stem contains only its preserved first readiness XML and no screenshot.
- Permanent prevention: all subsequent device-matrix actions are invoked by exact, unique, clickable text/content semantics from a freshly retained pre-tap XML. The helper rejects missing, duplicate, non-clickable, invalid or empty bounds and refuses to overwrite evidence.
