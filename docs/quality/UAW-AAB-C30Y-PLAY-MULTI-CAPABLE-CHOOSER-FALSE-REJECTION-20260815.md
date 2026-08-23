# UAW AAB C30Y Play multi-capable chooser false rejection

Date: 2026-08-15
Regression: `REG-20260815-2211-AAB-C30Y-PLAY-MULTI-CAPABLE-CHOOSER-FALSE-REJECTION`
Status: resolved; one-element selection and exact version verified

The visible Play **Upload** control opened a file chooser, but the retry guard
incorrectly rejected it because the chooser supports multiple files. No file
was selected or transferred, and no Save, Next, rollout, count, track or device
mutation occurred.

The corrected retry may accept a multi-capable chooser but supplies exactly one
absolute file path: the sealed r60.48 AAB. Play's visible artifact row must then
show version code `2026081348` before any later action.

## Resolution

The corrected retry accepted the multi-capable chooser but supplied one file
path only. Play completed transfer and visibly identified the sole selected
artifact as `2026081348 (1.0.0-r60.48)`; r60.47 remained not included.
