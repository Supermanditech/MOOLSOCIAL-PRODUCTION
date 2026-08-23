# C30O Play Integrity Dev-project link and temporary-access cleanup evidence

- Date: 2026-08-12
- Play app: MoolSocial
- Play app ID: `4974778280277295872`
- Cloud project: MoolSocial Dev Trial
- Cloud project ID: `moolsocial-dev-503018`
- Cloud project number: `760290687711`
- Package: `com.moolsocial.app`

## Linked state

Play Console verified project number `760290687711` as the sole linked Google Cloud project after the founder accepted the temporary project Owner invitation. A fresh Play settings reload after IAM cleanup continued to show the same linked project number.

Default Play Integrity responses now shown as On:

- App licensing: `LICENSED`, `UNLICENSED`, `UNEVALUATED`
- Application integrity: `PLAY_RECOGNIZED`, `UNRECOGNIZED_VERSION`, `UNEVALUATED`
- Device integrity: `MEETS_DEVICE_INTEGRITY`

No optional response, encryption, testing, store-listing, release-track, or quota setting was changed.

## Temporary-access cleanup

Immediately after the verified link:

- removed project `roles/owner` from `user:supermanditech@gmail.com`;
- removed project `roles/browser` from `user:supermanditech@gmail.com`;
- verified that the account has no remaining IAM binding on `moolsocial-dev-503018`;
- deleted the project-level `iam.allowedPolicyMemberDomains` override;
- verified that the project again inherits the organization restriction and the effective allowed value is only Workspace customer ID `C02baohu3`.

The Play link remained present after cleanup. No private integrity verdict or request payload was read.
