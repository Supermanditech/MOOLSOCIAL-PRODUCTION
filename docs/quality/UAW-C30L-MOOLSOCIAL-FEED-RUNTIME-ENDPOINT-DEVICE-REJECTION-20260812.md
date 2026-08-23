# C30L MoolSocial Feed runtime-endpoint device rejection

## Result

C30L r60.39 is rejected and preserved. The deployed Dev `moolSocialContent` revision is not the cause of the empty Feed: the installed APK did not call it.

## Proof

- `social_content_gateway.dart` selects `UnavailableSocialContentGateway` when `MOOLSOCIAL_SOCIAL_CONTENT_URL` is empty.
- C30L's exact `requiredRuntimeDefines` does not contain that define.
- `check-apk-regression-gate-state.ps1` also omits it from the permitted device-review define names.
- `SharedSession.socialContentAvailable` is therefore false and the Social consumer does not invoke `loadSocialFeed` during initialization or Retry.
- The OPPO capture shows the clean empty state, while bounded Dev service logs show no corresponding mobile request.
- C30K separately verified 36 durable posts and 48 media objects; the corpus is preserved and is not re-applied.

## Recovery gate

Do not rebuild r60.39. A future separately authorized successor must carry the exact Dev endpoint through a hardened machine-state allowlist, reject missing/non-Dev values in focused controls, prove an authenticated call before build consumption, and then replay the real multi-author Feed on OPPO.
