# C24B3 MoolSocial launcher width rejection — 2026-08-09

The first connected-navigator focused run rejected all six tests because the old 132 px launcher geometry was retained after changing `Mool` to `MoolSocial`. The icon, gap and longer label exceeded the available width by 31 px at the default test font and by up to 82 px in the 320 px / 1.4 text-scale case.

The corrected focal launcher removes the redundant icon, keeps the capsule height at 56 px, and derives a bounded width from the scaled label size. It must remain inside 320 px, preserve at least a 44 px tap target, and pass all adaptive chooser cases without overflow.
