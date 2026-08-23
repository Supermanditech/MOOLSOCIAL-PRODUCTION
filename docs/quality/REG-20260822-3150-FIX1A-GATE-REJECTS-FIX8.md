# REG-20260822-3150 — FIX1A gate rejects FIX8

Date: 22 August 2026

State: registered; no later gate or cycle credit

After the shared C34P gate was repaired and passed, the inherited FIX1A
all-eight gate rejected the exact selected FIX8 source-repair ticket because its
authorized descendant set predates FIX8. No later gate or device action ran.

Root cause: the FIX1A gate recognizes its earlier FIX5 descendant but not the
new audit-confirmed repair descendant.

Prevention: add only the exact FIX8 ticket/hash branch while preserving all
FIX1A source, provider, privacy and held release assertions plus unrelated-ticket
negative coverage. Restart both full cycles after generation replay.
