# C20H UIAutomator bound-center string concatenation rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

The first attempt to tap `Open YouTube Videos` parsed bounds
`[204,1328][356,1424]` but added the regex capture strings before numeric
conversion. PowerShell concatenated the digits and produced off-screen
coordinates `102178,6640712`. Android ignored the tap; two selected-state
values showed Social/Shorts remained current. No evidence was admitted or
mislabeled.

## Prevention

The device helper casts every endpoint to integer before arithmetic, rejects
centers outside the physical 720×1600 display, and requires two consecutive
post-tap hierarchies with the exact expected selected semantic before saving a
screenshot.
