# C30T Social Account creator-workspace compliance containment — 2026-08-13

## Finding

The reviewer-facing Social Account sheet linked to an in-memory Creator workspace and advertised publishing, distribution and earnings. Its legacy YouTube path simulated connection in local session state. That surface is outside the declared public discovery plus separately user-initiated minimum `youtube.readonly` use case and risks implying an upload/distribution capability that remains explicitly gated.

## Bounded correction

Replace only the Social Account entry with the production read-only YouTube connection route and truthful minimum-access, disconnect and Google-permissions copy. Do not redesign or delete broader Creator routes and do not enable upload.

## Verification

The focused Social Account test proves the read-only YouTube connection entry and minimum-access copy are present and the `Creator workspace` claim is absent. The production connection suite continues to prove that the read-only profile cannot render upload and that upload requires explicit separate authorization. The combined selection passed `12` tests. Evidence SHA-256: `2BF1EA7CF24BB61F51586C29DE9B15A438D3176E81B7B0B3E8B33D5617586C7D`.

Release configuration was restored to 15 plugins with no Integration Test plugin and no release APK. No OAuth action, backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
