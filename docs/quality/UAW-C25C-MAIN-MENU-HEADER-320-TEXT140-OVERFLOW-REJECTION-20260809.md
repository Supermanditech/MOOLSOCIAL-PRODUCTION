# C25C main-menu header overflow at 320/140% — rejection

Date: 2026-08-09

The first compiled C25C widget run rejected the popup at 320 logical pixels and 140% text scale. Its nested icon/brand header row overflowed horizontally by 69 pixels. The six main controls mounted and the remaining tests advanced, but the cycle is rejected.

The correction must constrain only the brand label, preserve its one-line identity, retain a separate 44 px Close control, avoid scrolling, and rerun the same 320/140% test.
