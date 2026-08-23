# C21H unparenthesized Test-Path OR expression rejection

Date: 2026-08-08

The r60.20 launcher activity opened successfully and the first PNG/XML pair was captured to `/data/local/tmp`, but the local no-overwrite guard combined two `Test-Path` calls around `-or` without parentheses. PowerShell rejected the duplicate `LiteralPath` binding before either local pull occurred.

The corrected step confirms both local targets are absent with separately parenthesized calls and pulls the already captured remote files. It does not relaunch, recapture, build or install.
