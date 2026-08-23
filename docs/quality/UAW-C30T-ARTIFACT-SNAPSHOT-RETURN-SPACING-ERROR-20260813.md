# C30T artifact snapshot return-spacing error

Date: 2026-08-13

The compact post-test restoration command used `return'absent'` in its artifact snapshot function. Since the release APK was absent, PowerShell attempted to run `returnabsent`, then emitted file lookup/hash errors. The command's plugin count is informative, but its artifact comparison is rejected.

The retry uses a multiline snapshot helper, `return 'absent'`, and terminating error behavior. No build, APK, AAB, backend, provider, device, Play, Hosting or communication action was authorized or intentionally performed.

The corrected exact state readback passed: release APK absent; release AAB remains the sealed C30S artifact at 93,201,374 bytes and SHA-256 `2B06AEE022AED4019AE88AF4278A218FEA4F14F3D49F94CDC591DA855458AD55`; release registrant contains exactly 15 plugins and no `IntegrationTestPlugin`.
