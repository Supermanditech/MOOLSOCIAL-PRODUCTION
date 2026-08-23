# REG2714 — C34I source manifest mutable-state self-reference

## Observation

The first C34I registry-2684 whole-source draft was generated with both the
mutable detailed candidate state and mutable aggregate state in its file list.
Binding the draft hash back into either state would necessarily change a
manifested file, making the source seal self-referential. The manifest was not
bound and no source cycle started.

## Root cause

The attempt to strengthen candidate-owner coverage did not distinguish
immutable release owners from lifecycle state files that must advance through
manifest binding, cycle qualification, build, upload, install and device
acceptance.

## Prevention

Retain the registry-2684 file as a rejected draft. Manifest the immutable C34I
ticket, actor policy, gates, runbook, founder authority, browser qualification,
launcher and preparation owners, but explicitly exclude the two mutable state
files. The candidate gate enforces their exact schema, identity, parity,
registry seal, policy hash, counts, authorities and phase transitions. Generate
a fresh registry-numbered manifest only after this rule is registered.
