# REG-20260821-3060 FIX7 multifile patch invalid hunk file boundary

## Observed failure

The combined FIX7 creation and FIX6/gate/policy update patch contained an
invalid hunk marker immediately before a new file-update boundary. `apply_patch`
rejected it before changing any file.

## Root cause

Four independently structured owners were combined into one hand-written patch
and the transition from a JSON hunk to the next file retained a stray marker.

## Impact

- no FIX6 ticket, FIX7 ticket, gate or policy file changed;
- qualified source and tests remain unchanged;
- no build, Play, OPPO, provider or device action ran.

## Prevention and authorized retry

Create FIX7 independently, then update FIX6, its gate and coordination policy in
separate patches with exact local anchors. Never combine JSON tail changes and
new file boundaries behind a manual placeholder hunk.
