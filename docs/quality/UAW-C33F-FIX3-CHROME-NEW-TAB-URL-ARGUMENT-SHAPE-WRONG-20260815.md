# UAW-C33F FIX3 Chrome new-tab URL argument shape wrong

- Recorded at: `2026-08-15T10:31:13.7139099Z`
- Regression: `REG-20260815-2390-C33F-FIX3-CHROME-NEW-TAB-URL-ARGUMENT-SHAPE-WRONG`
- Scope: founder-authorized additive Firebase Android Play app-signing SHA-1 repair.

The Chrome tab call used an object URL argument and created `about:blank`. The page had no title, headings, or certificate content. No certificate value was read, emitted, or persisted, and no Firebase or Play mutation occurred.

The retry must use the Chrome skill's documented string URL argument, validate the allowed Play Console domain on the resulting tab, then continue with value-free readiness checks.
