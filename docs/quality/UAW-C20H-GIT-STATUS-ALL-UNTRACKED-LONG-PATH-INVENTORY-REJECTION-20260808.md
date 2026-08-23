# C20H all-untracked Git inventory long-path rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

`git status --porcelain=v1 --untracked-files=all` descended into historical
browser-profile artifacts and emitted multiple Windows filename-too-long
warnings. Its 51,998 returned entries were therefore not accepted as a full
dirty-tree seal even though Git exited zero. No source, APK or device changed.

## Prevention

The successor build uses Git's path-safe `--untracked-files=normal` inventory,
which records every tracked change and each untracked directory/file owner,
then separately binds the exact C20 source owners through the qualified source
fingerprint. Warning-bearing recursive artifact enumeration is not used.
