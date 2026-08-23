# REG-20260820-3035 Facebook Android key-hash and Install Referrer screenshot exposure

## Incident

A Facebook Basic settings screenshot was returned without redacting the Android
key-hash field and Install Referrer Decryption Key. Codex does not repeat,
retain or use either value in durable evidence.

## Impact

- The signing private key, keystore password, Facebook App Secret and OAuth
  tokens were not exposed by these fields.
- The certificate fingerprint is not sufficient to sign an app, but remains a
  founder-controlled configuration value under this task's privacy boundary.
- The Install Referrer Decryption Key must be treated as exposed; MoolSocial
  does not require referrer attribution for authentication.
- No provider save, build, Play or OPPO action is claimed from the screenshot.

## Root cause

The screenshot included the lower Android platform section after the task had
explicitly required screenshots to exclude key-hash and credential surfaces.

## Prevention

Never return the Android platform section. Crop every later Meta screenshot to
the exact edited fields above all key-hash/referrer material. Keep automatic
purchase/subscription/referrer features disabled for the auth-only integration,
and require provider-authoritative rotation or documented non-use of the
referrer key before App Review.

## Founder decision

The founder directed that neither value be rotated or modified. The Android
certificate hash is treated only as a signing fingerprint. The Install Referrer
key is explicitly unused by this authentication-only integration; automatic
purchase, subscription and referrer/advertising features remain disabled. If
that product scope changes later, key rotation and a separate privacy review
become mandatory before use.
