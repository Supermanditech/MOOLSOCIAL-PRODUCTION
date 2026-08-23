# C30T Chat retired-prototype state-contract finding — 2026-08-13

## Finding

The production Chat UI intentionally exposes text-only sending, but a permanent global-navigation test still required retired reply and attachment previews. The exact test failed because those controls no longer exist. `ChatSession` nevertheless retained dormant global reply/attachment state, and a legacy attachment label was still tappable even though the model carried no provider URI or bytes; its callback falsely claimed the attachment opened and its global notice was not visible in the thread-owned banner.

## Bounded correction

Keep the real unsent text draft across the Mool round trip, prove the retired previews remain absent, remove the dormant composer state, and present legacy labels only as non-interactive references. Do not add attachment, reply, reaction or media capabilities.

## Verification

The pre-fix permanent test failed at the retired `chat-reply-preview` expectation as expected. Evidence SHA-256: `A9FC8026E575556ACC6B696B7FD5B40AFBDCCE7C16D740E494BF83ADF03E9FF1`.

The permanent C05 global-navigation file, production Chat gateway suite and Chat user-journey suite then passed `23` serial tests. They prove current compact/standalone Mool launchers open the connected navigator, system Back restores the exact owner, the unsent text draft remains exact, retired reply/attachment controls remain absent, legacy labels are non-interactive references, and existing load/send/retry/recipient isolation remains green. Evidence SHA-256: `FF5CA4D08E09F6DCB43BA7F3C834E8393F115063F1214B0A08770BDAA999D432`.

Release configuration was restored to 15 plugins with no Integration Test plugin and no release APK. The preserved C30S r60.44 AAB remains byte-identical. No backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
