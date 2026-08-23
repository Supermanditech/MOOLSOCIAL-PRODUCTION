# C30T executable gate script path assumption

Date: 2026-08-13

An authority-precedence search included a guessed `scripts/check-play-internal-aab-gate-c30t.ps1` path that is not present. The command returned useful matches from existing files but exited nonzero, so it was rejected as complete audit evidence.

Permanent prevention: enumerate exact C30T scripts first and supply only verified literal paths to a bounded search.
