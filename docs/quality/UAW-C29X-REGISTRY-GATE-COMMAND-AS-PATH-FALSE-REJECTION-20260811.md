# C29X registry gate command-as-path false rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-CHAT-GLOBAL-EDGE-AND-CONTRAST-C29X`
- Result: regression-memory gate rejected before retry

The new import regression entry placed a direct `flutter analyze` command string in its `gates` array. The registry checker correctly requires every gate value to resolve to an existing repository owner and rejected the string as a missing path. The entry now names only the existing regression-memory script; direct focused analysis remains a separately executed command recorded in completion evidence. No formatter, analysis retry, test, build, install or device action ran after the gate failure.
