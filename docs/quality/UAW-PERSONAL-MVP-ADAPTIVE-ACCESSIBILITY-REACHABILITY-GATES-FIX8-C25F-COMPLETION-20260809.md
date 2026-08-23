# C25F adaptive accessibility and reachability completion

Date: 2026-08-09

## Outcome

C25F is complete. The main-only MoolSocial menu and destination-local rails are
qualified at 320, 390 and 430px, 100% and 140% text, with all controls at least
44px, no horizontal navigation scroll, one-tap Chat for all six families and
cross-owned Bus/Medicine surfaces, exact Chat return and immediate reduced
motion.

The reduced-motion audit found and corrected a real overlap: route transitions
now use zero duration under `disableAnimations` or `accessibleNavigation`, while
standard motion remains 240ms inside the approved 180-320ms interval.

## Evidence

- Full Flutter analysis: no issues.
- One uninterrupted predecessor-required cycle: 38/38 files passed.
- C25B-C25F, R11 Chat and C10E motion focused group: 41 tests passed.
- C25F adaptive file: 15 tests passed across required widths/text scales and
  all real family/Bus/Medicine Chat journeys.
- C25A, C25F, MVP scope, delivery lock and permanent regression-memory gates:
  passed.
- Protected Social successor: 178 files,
  `9d79db1aa83d52d26e5f4a494315a7c213a504da6cba231346772aadac9af4e5`.
- Protected Buy successor: 43 files,
  `37d946cd050d378a9ee60fd8b19716f59acba25dbc0c0593a9136668fcd120e7`.
- Permanent regression registry: 836 entries, all applicable memory checks
  passed.

## Preserved state

Branch `remediation/prototype-conformance-2026-07-20`, HEAD
`f6dfe7587aa02d782e94282d14af8bafff48ded0`, and the complete tracked/untracked
dirty tree remain preserved. Connected OPPO CPH2375 still runs rejected
`1.0.0-r60.23` (`2026080923`), first install `2026-08-04 02:51:59`, last update
`2026-08-09 11:09:23`; no build or install authority was opened.

C25G host qualification is the only lawful successor ticket.
