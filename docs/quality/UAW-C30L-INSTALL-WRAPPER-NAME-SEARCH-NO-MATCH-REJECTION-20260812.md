# C30L install-wrapper name search no-match rejection

- Scope: local read-only install owner discovery.
- Rejection: the bounded script-name search found no dedicated install or APK-qualification wrapper and exited nonzero.
- Prevention: use the already accepted exact-serial `adb install -r` in-place procedure after checksum, identity and machine-state gates; do not retry speculative script-name searches.
- Device impact: none; install count remained zero.
