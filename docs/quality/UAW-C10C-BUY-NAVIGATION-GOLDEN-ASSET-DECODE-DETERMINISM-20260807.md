# UAW C10C Buy navigation golden asset decode determinism regression

- Registry: `REG-20260807-200-BUY-NAVIGATION-GOLDEN-ASSET-DECODE-NONDETERMINISM`
- State: resolved; deterministic image-settling and strict-golden gate active
- Trigger: `buy-v2-r58-8-7-360x800-android-cart.png` passed strict comparison alone, then failed by 8.34 percent in the combined qualification run.
- Evidence: the generated master used fallback product symbols while the generated test image contained decoded product photography in the Cart and recommendation cards.
- Root cause: the capture did not establish deterministic completion of every visible image provider before comparing pixels.
- Durable rule: navigation golden setup precaches visible image providers and renders a stable frame before `matchesGoldenFile`; both isolated 5/5 and combined 82/82 qualification now pass.
