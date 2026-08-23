# C29Y posting-ready Create and four-choice polls source completion

- Date: 2026-08-11
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Result: source complete; combined successor OPPO replay pending

Create now opens directly into the existing real MoolSocial composer with no intermediate format screen and no automatic keyboard. Text, Image, Carousel, Image Poll, Quick Poll and Quiz remain one tap away. Image Poll, Quick Poll and Quiz require and render four complete choices. A distinct one-tap YouTube Short action opens the existing truthful creator route; no upload readiness is claimed. The composer hides the global dock for usable keyboard space and its close action returns to the real Feed rather than the deleted format menu. Existing posting, media, validation, error and retry owners remain authoritative.

Verification passed:

- exact Dart formatting and focused analysis with zero issues across three production owners and six affected test owners;
- `social_v2_create_publication_test.dart`: 5/5, including two-choice rejection, four-choice publication, direct entry, no initial IME, one-tap YouTube callback and 140% text scale;
- `screen04_universal_v2_conformance_test.dart` plus customer-copy gate: 31/31, including all supported viewports at 100% and 140%, composer lifecycle and connected navigation;
- continuous Social, named-state, native YouTube dock and C29N keyboard/global-edge suites: 25/25;
- targeted `git diff --check`: exit 0;
- protected customer-copy owner remained at SHA-256 `8BB8D600D9072C69543D38B8FC20868DA7F352CFB554D5891E624BF997351CF9`.

No new screen, route, service or backend owner was added. No build, install, OPPO mutation, deployment, OAuth flow, provider change, upload, commit, push or promotion occurred under C29Y.
