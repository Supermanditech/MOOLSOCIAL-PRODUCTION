# REG-20260820-3048 File Explorer Home accessibility unrelated recent-item exposure

## Observed failure

The first Windows File Explorer accessibility observation was taken on Home and
returned an oversized tree containing unrelated Recent-item filenames and
account text. The output is outside the keystore-filename-only scope and is
rejected.

## Root cause

Computer control requested the full accessibility tree before confining File
Explorer to the search box or an exact scoped folder.

## Impact

- no click, typing, search, file open, move, copy, delete or creation occurred;
- no keystore content or password was read;
- no repository, provider, build, Play, OPPO or device state changed;
- unrelated visible Home metadata was over-emitted.

## Prevention and authorized continuation

Do not capture File Explorer Home accessibility again. Use a bounded
filename-only filesystem search over explicitly authorized common user folders,
exclude the Android debug keystore, and emit only a match count/selection
marker without paths or unrelated metadata.
