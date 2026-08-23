# C22H Social Create auto-opened IME rejection

- Date: 2026-08-09
- Accepted Social states before rejection: Shorts, Videos, Feed

## Rejection

Create became the selected Social subaction, but `dumpsys input_method`
reported `mInputShown=true`. The helper therefore rejected the screenshot as
obscured and stopped before either Eat step ran.

## Prevention

Send Android Back once to dismiss the IME only, reacquire the hierarchy, prove
`Create, current` and the Social family remain selected, require
`mInputShown=false`, and only then accept the Create screenshot/XML pair.
