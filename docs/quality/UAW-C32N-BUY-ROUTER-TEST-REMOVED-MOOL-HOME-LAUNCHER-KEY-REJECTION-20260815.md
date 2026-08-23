# C32N Buy router test removed Mool home-launcher key rejection

Date: 15 August 2026
Regression: `REG-20260815-2264-C32N-BUY-ROUTER-TEST-REMOVED-MOOL-HOME-LAUNCHER-KEY-REJECTION`

C32N initial focused cycle 1 used a 58-file fingerprint `661B3FCC04257C06AA99D5B0BB3D680ED4BFC5BB19AF950CAC8809107CE961C7`. Regression memory, MVP scope/delivery, approved UI locks and C32M/C32N gates passed on both PowerShell hosts. The Flutter group then passed 43 cases and failed three cases in `apps/mobile/test/ui_v2/buy/buy_v2_router_test.dart` because `mool-home-launcher` was not present.

No analyzer or second cycle ran. No runtime, protected baseline, backend, build, Play or OPPO state changed. Diagnosis must compare the failing predecessor key with the later accepted compact Mool navigation owner before any edit or retry.
