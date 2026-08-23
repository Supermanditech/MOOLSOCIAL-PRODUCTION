# C30T Android App Links Play-signer mismatch finding

Date: 2026-08-13

Read-only live HTTP inspection found:

- `https://moolsocial.com/.well-known/assetlinks.json`: HTTP 200, package `com.moolsocial.app`, certificate SHA-256 `CB:DF:C5:96:9A:D5:1E:D5:70:AF:B1:CF:2F:E6:03:77:E5:59:D4:3F:59:D5:9E:2A:B6:6C:CA:F7:8E:A9:AC:25`.
- required Google Play app-signing SHA-256: `47:B2:8C:7D:DE:2B:61:CA:B6:A7:74:8C:90:19:A3:B5:73:76:B3:BE:1D:C1:63:D4:82:53:BB:A3:5B:63:CD:D9`.
- `https://moolsocial.com/app/social?sub=feed&item=audit-probe`: HTTP 404.

The current live association therefore cannot verify the Play-installed app identity, and the intended Social URL has no browser fallback. Current repository source has neither the live association file nor the fallback page; `firebase.json` also ignores dot-prefixed paths.

Local source correction and static tests are authorized. Firebase Hosting deployment is an external public-site write and remains explicitly held. Live HTTP and OPPO verified-link proof are mandatory after separate founder deployment authority.

## Local source correction and verification

- `apps/web/public/.well-known/assetlinks.json` now owns the exact Play app-signing SHA-256 and package.
- Firebase Hosting no longer excludes the required dot-prefixed `.well-known` source.
- `apps/web/public/app/social/index.html` provides a noindex browser fallback and preserves the exact `item` query in its same-origin open-app action.
- static public-site result: 7 passed, 0 failed; SHA-256 `6BA68E511AEE329ED3162DD50A276A25AAF8431E8751E80B32EC6DF7FA835C04`.

No Hosting deployment occurred. The live association and live 404 remain unchanged until separately authorized.
