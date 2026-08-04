# BUY-FV2 R58.8.2 order Assist context continuity handoff

Date: 4 August 2026

State: **TECHNICALLY/DEVICE QUALIFIED — FOUNDER REVIEW PENDING**

The exact OPPO defect was Orders -> Wholesale `PO-240783` -> Help showing
unrelated Shop `MS-240782`. The source always chose the first non-delivered
order even though the session retained the valid selected-order route owner.

Candidate `BUY-R58-ORDER-ASSIST-CONTEXT-CONTINUITY-FIX1`, profile
`1.0.0-r58.9` (`2026080405`), binds the existing Assist card to the exact valid
Tracking/Items order and keeps the existing general fallback elsewhere. Exact
app/test source is 2,441 files / SHA-256
`5D067817F2C0A49105BC3CB1C030749DF878178F50E2C552741AB5D8CE6358BB`.
The wrapper APK and checksum-matched OPPO install are 134,197,729 bytes /
SHA-256
`9526B671D3F6F9C1ED382E4A56FE96CD88254ECABDFB7F99A1B7E8ACB61E23AA`.

Focused/related/responsive checks, two complete Buy regressions at 330 active
passes plus 18 established skips, every mandatory host/HTML/protected gate and
the one-candidate machine passed. OPPO passed all three active order families,
exact card/Back, stale-general fallback, semantics/keyboard, hot resume,
truthful recreation, dialer/screen interruption, bottom navigation, visible
static reduced motion with restored 1x settings, corrected joined-frame p95
20.020 ms / max 22.037 ms and zero classified runtime failures.

Evidence:
`artifacts/quality/buy-order-assist-context-continuity-r58-8-2-fix1-20260804-143`.

No live support, backend order refresh, provider, payment, stock, fulfilment or
entitlement outcome is added. Technical/device qualification is not founder
approval; no protected baseline was updated.

