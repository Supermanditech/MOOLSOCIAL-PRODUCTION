# C20H gfxinfo Flutter surface frame assumption rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

A live Doctor-to-Salon tap completed and Salon / Book was confirmed by fresh
semantics, but `dumpsys gfxinfo com.moolsocial.app framestats` supplied zero
frame rows newer than the pre-tap maximum. The Activity framestats stream is
therefore rejected as evidence for Flutter motion on this OPPO runtime.

## Prevention

The exact MoolSocial compositor surface is inventoried from SurfaceFlinger. A
retry uses that surface's latency timestamps, requires new compositor frames,
and independently proves the exact destination selection twice. The phone's
animation scales remain unchanged.
