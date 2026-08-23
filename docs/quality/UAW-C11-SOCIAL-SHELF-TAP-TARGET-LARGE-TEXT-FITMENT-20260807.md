# C11 Social shelf tap-target and large-text fitment defect

Date: 2026-08-07

Regression ID:
`REG-20260807-245-C11-SOCIAL-SHELF-TAP-TARGET-LARGE-TEXT-FITMENT`

The first C11 focused widget run measured the Social Create action at only 38
logical pixels high and reproduced a one-pixel vertical overflow at 320x568
with 140% text. The existing fixed 48-pixel context-tabs shell constrained a
nominal 52-pixel action and left only 22 pixels for provider attribution plus
its scaled label.

Permanent prevention: the Social local shelf allocates a real minimum
44-by-44 action region after all outer padding, retains label fitment at 140%,
and uses only finite 160–240 ms selection acknowledgement. Reduced motion
removes the selection scale and sheen. The C11 responsive test measures the
actual keyed action size and rejects every rendering exception.
