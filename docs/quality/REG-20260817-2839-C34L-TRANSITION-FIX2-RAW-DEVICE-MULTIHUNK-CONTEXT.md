# REG2839 — C34L transition FIX2 raw-device multihunk context

Date: 17 August 2026
State: registered atomic patch rejection; zero writes

## Mistake

The transition FIX2 raw-device correction combined distant OPPO and journey
hunks using remembered schema context. The live journey field list wrapped
differently, so `apply_patch` rejected the complete patch atomically and no hunk
applied.

## Prevention

Read fresh bounded local slices for the OPPO and journey schema regions and
apply one exact anchored patch per region. Never combine distant schema edits
under remembered wrapping or transcribed field lists.
