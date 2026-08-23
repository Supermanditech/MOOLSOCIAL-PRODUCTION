# REG2770 — C34L browser-proof transition/phase conflict

Date: 17 August 2026
State: registered independent audit finding; no release action

## Finding

The PRE-AAB-3 browser proof schema requires transition `upload-succeeded` with
phase `preupload`. The qualified C34L lifecycle maps `upload-authorized` to
`preupload` and `upload-succeeded` to `postupload`. A browser proof using the
new checker therefore cannot also satisfy the canonical transition owner.
Existing fixtures did not compare this tuple with the lifecycle map. No
browser, provider, candidate, build, Play, OPPO, device, private or external
action occurred.

## Required correction

Bind the current-session browser proof to the exact `upload-authorized` /
`preupload` prerequisite. Keep Play upload-success evidence separate at
`upload-succeeded` / `postupload`. Project the transition/phase tuple from the
canonical map and add dual-host wrong-transition and cross-phase negatives
before the phase matrix resumes.
