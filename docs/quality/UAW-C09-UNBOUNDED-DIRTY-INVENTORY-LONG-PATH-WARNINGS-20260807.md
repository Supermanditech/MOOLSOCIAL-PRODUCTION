# C09 unbounded dirty-inventory long-path warnings

Date: 2026-08-07
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`

## What happened

The first in-memory source-fingerprint calculation invoked
`git status --porcelain=v1 -uall`. The repository contains a very large retained
artifact tree, including copied browser profiles with paths beyond the Windows
native path limit. Git completed with exit 0 but emitted long-path traversal
warnings. No file or device state changed, and that unbounded dirty-status hash
is rejected as candidate evidence.

## Prevention

Candidate identity uses tracked status without untracked traversal plus an
explicit scoped untracked inventory for production runtime, C09 contracts,
tests, scripts and current evidence. Retained historical artifacts are neither
rescanned nor APK inputs. Full untracked traversal of the repository is
prohibited for routine candidate sealing.
