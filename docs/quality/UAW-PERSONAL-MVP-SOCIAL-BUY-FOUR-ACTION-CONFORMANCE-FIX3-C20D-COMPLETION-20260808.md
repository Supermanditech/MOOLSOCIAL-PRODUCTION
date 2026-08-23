# C20D Social/Buy four-action conformance completion

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SOCIAL-BUY-FOUR-ACTION-CONFORMANCE-FIX3-C20D`

## Completed customer outcome

The existing Social and Buy production consumers are qualified against the
C20C shared neutral brand-glass system. Social retains four media-glass actions
and two provider-attribution SVGs; Buy retains four light-glass actions with no
blocking rail surface. Shorts, Videos, Feed, Create, Shop, Wholesale, Medicine
and Orders each become selected truthfully and leave the other actions one tap.

The real consumers pass at 320, 360, 390, 412 and 430 logical-pixel widths with
both 1.0 and 1.3 navigation text scale. Targets remain 48px, labels remain
13px/700 in a single scale-down line, provider icons remain 20px, neutral glass
retains visible background compositing and representative contrast remains at
least 4.5:1. Reduced motion is immediate.

## Qualification

- focused C20D real-consumer matrix: 3/3 pass, covering eight selected states,
  five widths and two text scales per family;
- C20D/C20C/C17C/C20B/Buy-motion/C10E compatibility shard: 38/38 pass;
- focused C20D Flutter analysis: no issues;
- C20D static gate with C20C and C20B predecessors: pass;
- placement, global navigation, C10E motion, approved UI, app brand, copy,
  interaction, Personal projection, MVP delivery/scope and permanent memory:
  12/12 pass;
- permanent regression memory: 439 entries, 310 applicable to implementation.

The first focused run's reused Social harness state was registered and corrected
with scenario-local widget identity before the qualifying retry.

## Release boundary

C20D required test-only acceptance; no production runtime source was changed.
No APK was built or installed. OPPO r60.18 remains preserved with installed
SHA-256 `88F82D203E1C8C565BE5DEBB61E6C1EF1F9E588017EADB9120D97B4B3081ED2C`.
C20E is the next eligible host-only child.
