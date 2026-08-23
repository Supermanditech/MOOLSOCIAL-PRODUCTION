# C30R MVP scope array-context recurrence

Date: 2026-08-12

While finishing the C30R scope-state transition after the runtime rejection,
an array patch again used manually reconstructed exclusion strings containing
spaces where the raw JSON uses underscores. `apply_patch` rejected the entire
patch before modification.

The device, installed app, Play release, evidence and current JSON are
unchanged by this failed patch. Prevention is now literal: no array block
replacement is permitted in this transition. Replace only one exact raw line
per patch, parse after each bounded set, and run all gates before any runtime
retry or external action.
