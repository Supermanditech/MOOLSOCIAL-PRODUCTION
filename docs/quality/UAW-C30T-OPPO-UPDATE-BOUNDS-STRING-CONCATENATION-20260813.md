# C30T OPPO Update bounds string concatenation — 2026-08-13

## Outcome

The first C30T Play Update tap command parsed the verified Update node bounds
but added the regex capture strings before division. The resulting logged
coordinate was outside the display instead of the verified node center.

The post-action Play UI showed **Cancel**, indicating an update was already in
progress. No second tap, uninstall, data clear, downgrade, sideload or ADB
install was attempted.

## Root cause and prevention

PowerShell regex captures were not cast individually to integers before
addition, and the computed center was not checked against the device display.
Future bounded device taps must:

- assign left, top, right and bottom to distinct integer variables;
- calculate the center only after those casts;
- read and assert the physical display bounds;
- assert the center remains inside the parsed node; and
- perform at most one tap.

An update tap must never be retried while Play shows Cancel, Pending or other
progress. This post-build operational entry does not authorize another AAB,
upload or installation attempt.
