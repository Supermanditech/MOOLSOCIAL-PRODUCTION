# C09 optional Tristate search failure

Date: 7 August 2026

An optional lookup for existing `Tristate`/`flagsCollection` use in the Screen
04 conformance test correctly returned zero matches, but was again invoked as
bare ripgrep and surfaced exit 1. No source changed. REG-20260807-140 records
the recurrence. C09 no longer uses bare optional ripgrep; bounded file reads or
the explicit exit 0/1/>1 wrapper are mandatory.
