# C30Q founder r60.40 removal readback

Date: 2026-08-12

The founder reported uninstalling MoolSocial from the connected OPPO. Immediate
read-only ADB verification proved that `com.moolsocial.app` is absent from both
the installed-only and installed-plus-uninstalled package lists and has no
package path for Android owner user `0`.

The prior r60.40 identity record, exact base APK and checksums remain retained.
They preserve the removed binary for audit, not its former private local app
data. That local data must now be treated as removed and non-restorable from the
identity record. Codex did not perform the uninstall.

`com.moolsocial.app.test` remains as a separate package and was not changed. No
C30Q candidate install, ADB successor install, second upload, Production/open/
public rollout, email or quota action occurred.

Machine-readable evidence:
`artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01/12-founder-r60-40-removal-readback.json`
