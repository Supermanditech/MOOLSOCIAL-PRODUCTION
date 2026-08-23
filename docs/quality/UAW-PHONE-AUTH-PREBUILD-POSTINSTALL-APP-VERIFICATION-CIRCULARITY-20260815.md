# Phone Auth prebuild/post-install app-verification circularity

- Regression: `REG-20260815-2467-PHONE-AUTH-PREBUILD-POSTINSTALL-APP-VERIFICATION-CIRCULARITY`
- Finding: the initial Phone ledger wording grouped provider prerequisites with Play-installed app-verification evidence and could create an impossible prebuild dependency.
- Impact: no AAB or authority was consumed; the current prebuild gate was already closed by the pending status.
- Prevention: prebuild requires source qualification, enabled Phone provider and qualified SMS-region policy only. Play Integrity/reCAPTCHA return and OPPO send/verify remain post-install candidate acceptance evidence.
