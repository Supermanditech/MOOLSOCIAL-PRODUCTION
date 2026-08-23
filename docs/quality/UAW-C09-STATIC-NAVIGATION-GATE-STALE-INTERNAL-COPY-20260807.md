# UAW C09 static navigation gate stale internal copy failure

## Incident

After the rejected r60.9 Mool Home wording was replaced with customer-facing
copy, `check-personal-mool-global-navigation-contract.ps1 -RequireImplemented`
reported that the shared outcome dock had no readable persistent overflow rail
contract.

The horizontal scroll container, minimum tap target, persistent overflow cue
and initial-frame overflow activation were still present. The false rejection
was caused by the checker requiring the exact internal accessibility sentence
`Scrollable main actions.`

## Root cause

The checker combined product wording and navigation mechanics into one static
condition. An implementation-oriented sentence was therefore treated as proof
of overflow behavior, which made the gate resist the required production-copy
correction.

## Permanent prevention

- The navigation checker requires the approved customer-facing semantic prefix
  `More MoolSocial options. Swipe horizontally to explore all`.
- Scroll direction, tap-target size, overflow-cue identity and initial-frame
  activation remain separate required source invariants.
- `check-user-facing-copy.ps1` independently rejects the retired internal
  phrases.
- Regression-memory validation keeps this rule available to future tickets.

No APK build, OPPO install, uninstall or application-data mutation was
authorized or performed by this correction.
