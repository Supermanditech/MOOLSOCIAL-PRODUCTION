# UAW AAB C30Y Play hidden file-input chooser timeout

Date: 2026-08-15
Regression: `REG-20260815-2210-AAB-C30Y-PLAY-HIDDEN-FILE-INPUT-CHOOSER-TIMEOUT`
Status: resolved; visible Upload control and exact version verified

The first Internal Testing upload handoff clicked the hidden file input. No file
chooser was emitted before the browser-control timeout, and the uncaught wait
reset that control session. No file transfer, Save, Next, rollout, upload-count
mutation, other-track action or device action occurred; release counts remained
`1/0/0` and upload authority remained available once.

The retry must use the visible **Upload** button with a caught chooser promise,
select only the sealed r60.48 AAB, and verify Play's visible version code before
any subsequent release action.

## Resolution

The retry used Play's visible **Upload** button, selected exactly the sealed
r60.48 AAB and completed transfer. Play visibly reported one bundle uploaded
and identified it as `2026081348 (1.0.0-r60.48)` before any Next or activation.
