# C16 ColorOS stale input-view signal false IME block

## Incident

After the bounded dismissal interval, the OPPO continued to report
`mIsInputViewShown=true` even though `mShowRequested=false`,
`mInputShown=false`, and a fresh screenshot proved Gboard absent with the full
Create content and both navigation rails reachable. Requiring the secondary
input-view flag to become false would create a false permanent device block.

## Root cause and prevention

On this ColorOS build, `mIsInputViewShown` can remain true after the visible IME
surface has been removed. It is retained as a diagnostic signal, not used alone
as overlay truth. The C16 gate requires `mShowRequested=false` and
`mInputShown=false`, then separately proves the rail is unobscured using a fresh
device screenshot and supported window-state evidence before navigation.
