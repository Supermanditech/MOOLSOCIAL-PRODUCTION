# Redmi r66.1 prebuild record

State: r66.1 review build and in-place Redmi install completed; installed checksum matches the built APK. Fresh UAT is in progress, not accepted or production-qualified. Earlier future-tense entries below preserve the prebuild sequence; actual receipts follow.

REG4497: the first bootstrap rejected the inherited raw registry pin. The new checkout was Git-clean and all 4462 records matched the exact source blob; only checkout newline bytes differed (raw SHA `BBB02FB3F01E2AA47EF4D4602066D40D700C2809E527A2F4C59D209D5B03F47C`). The primary registered this prevention and refreshed the local binding without altering any prior entry. No gate or product source was weakened.

Source implementation: `e2dd3bc706065fbc08d9c526c48e24374cd32e6e`, clean and exactly remote-equal on `work/cursor-ui/buy-card-overflow-v1-20260905`. Review continuation has this commit as its starting point. No later Codex branch is merged.

Reuse the source checkpoint's `docs/quality/cursor-buy-card-overflow-v1-20260905/RESULTS.md`: 34 focused checks passed; full analysis zero issues; two declared connected selections each 167 passed / one pre-existing skip. Three baseline-reproduced obsolete assertions and five historical golden comparisons remain explicitly outside those selected passes, not hidden or updated to force green. Full historical suite is not claimed green. This is a non-promotable debug candidate for current visual/UAT investigation.

Complete external run evidence is retained under `C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905`. All generated comparison images are preserved there with a manifest; their tracked originals were restored. Interrupted/truncated read outputs and the unsupported `--exclude-name` attempt were not used as test passes (REG4491); required reads were recovered in bounded pages.

Candidate: `UAW-CURSOR-BUY-R66-1-REDMI-REVIEW-20260905`; version `1.0.0-r66.1`; code `2026090501`; `CursorUiReview` / debug / `com.moolsocial.app.cursorreview`.

Premium motion: reuse existing finite/event-driven Buy micro-interactions and reduced-motion state, unchanged by the layout correction. No new motion effect, shape, colour, font shrink or business-state animation. Network-driven motion and genuine payment/delivery completion remain dependent on authoritative adapters. Policy: `config/buy-premium-motion-policy.json`; coverage: `docs/quality/BUY-PREMIUM-MOTION-SURFACE-COVERAGE-20260802.md`. The candidate contract is `docs/quality/UAW-CURSOR-BUY-REDMI-UAT-V1-20260905.md`.

Protected boundaries: only the catalogue source and focused test differ functionally from f94cfd47; no locked Screen 01–03, auth, shared Chat/Care, Work/Workspace, native configuration, dependency or backend owner changed. Build wrapper must restore tracked generated support metadata byte-for-byte. No new architecture, route or screen.

Prior APK/evidence disposition: existing r65.11 review app/data remain until in-place review update; no deletion, downgrade, production replacement or old binary reuse. Founder-approved historical cleanup disposition remains at the inherited `historical-evidence-disposition.md`; current evidence is not waived. There is no rejected APK from this new ticket.

Gate receipts, full source-manifest fingerprint, build HEAD, APK checksum and installed checksum will be appended only after actual successful commands. Startup/config regression prevention uses the inherited registry and existing package-isolation/build-foundation checks, not inferred live authentication success. WhatsApp and OPPO remain excluded.

## Actual prebuild receipts

- Review HEAD `49d6d413d40708c913805b8201ed2bcae1c968a1` is pushed and exact remote-equal; task-start gate passed with registry 4463 / `F7C0E024CD6EEDF64A9326B5ED8ECE7EC48FE2035BA597562F6629D17A453C10`.
- Before candidate receipt updates, raw Git status had zero bytes/records, SHA `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`, zero stderr bytes and native exit 0. The digest helper emitted an irrelevant VoidTaskResult; no file names/status contents leaked and no false clean result was inferred from it. Future helper task returns are explicitly voided.
- Scope gate passed the exact review manifest with build/install authority, no runtime/backend/reference write and no external-service write.
- Existing source-manifest generator selected 710 live source/test/build-control owners. Manifest SHA `02D3AF0C8BBADCE80725E24695E4BA5F921383BE62B6787046043C6D95408044`. No product source differs from the clean e2dd3bc7 checkpoint.
- Public-auth sideload build-foundation checks passed with native exit 0, using the existing archive-aware memory option through process-scoped PowerShell defaults. Full receipt: external `r66-1-build-foundation-attempt1.stdout.log` and `.stderr.log`. The generic debug profile was checked; no private auth provider, Play or release action occurred. The existing support guard hydrated the locked dependencies and restored tracked generated files.
- CursorUiReview wrapper/package-isolation positive and negative fixtures passed, native exit 0: external `r66-1-package-profile.stdout.log` / `.stderr.log`. Only `com.moolsocial.app.cursorreview` is eligible for this debug build.
- A fresh clean-checkout repeat of both complete focused suites passed: 34 passed, 0 failed, 1 pre-existing capture skipped, native exit 0; `r66-1-clean-checkout.stdout.log` / `.stderr.log`. No golden updating or assertion suppression.
- Two source-identical connected selections and full analysis remain those recorded in the inherited catalogue RESULTS with exact stdout hashes. The exclusions and production-release limitation remain unchanged.

The APK and builder provenance are generated into the ignored, repository-contained `apps/mobile/build/cursor-review-r66-1-20260905` directory. The artifact will be checksum-preserved externally and indexed here after creation; no placeholder binary or overwrite is allowed. Mandatory post-build plugin/package validation, installed checksum comparison and all device gates remain pending.

## Actual build and installation receipts

- Existing review wrapper completed successfully at 06:18:58 IST on 2026-09-05, native exit 0; Gradle 283.3 seconds. All 13 prebuild gates and the postbuild plugin/package checks passed. The dependency guard restored the tracked generated support metadata; no source/dependency change was introduced by building.
- APK: 209,417,681 bytes; SHA-256 `30A71FE8B6696BF51400FBED5A90C3179E25CE0A6153A998F5A041657C9D35C3`. External preserved copy: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/r66-1-cursorreview.apk`. Full builder provenance remains beside the original APK in the ignored review build folder.
- One build console poll was truncated and native child progress partly bypassed redirected PowerShell output. Preserved stdout/stderr, final wrapper receipt and provenance establish completion; a complete raw build-console transcript is not claimed.
- Redmi `TG8HCYTGGQT885OF`, Android 13: `adb install -r -t` succeeded at 06:20:26 IST, preserving existing review data. Installed version `1.0.0-r66.1-cursorreview`, code `2026090501`, package `com.moolsocial.app.cursorreview`. `pm path` followed by on-device `sha256sum` matched the built APK exactly. Production package and OPPO were untouched.
- Cold launch of `com.moolsocial.app.cursorreview/com.moolsocial.app.MainActivity` succeeded; `am -W` reported 10,830 ms. This is launch evidence, not a first-frame performance acceptance. Fresh capture 001 records the review UI.
- Device rotation was originally free (`accelerometer_rotation=1`, `user_rotation=0`), density 320, font scale 1.0. A temporary `wm user-rotation lock 0` enables portrait auditing; restore `wm user-rotation free` at handback. No app orientation fix is implied.
- No WhatsApp, real commerce, production install, APK promotion or integration. Current findings prevent any full-UAT acceptance claim.
