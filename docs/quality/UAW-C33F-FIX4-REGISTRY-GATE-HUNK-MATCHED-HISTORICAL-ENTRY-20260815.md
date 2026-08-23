# UAW-C33F FIX4 registry gate hunk matched a historical entry

Date: 2026-08-15

A generic patch context for a repeated `gates` array matched historical REG-20260815-2374 instead of active REG-20260815-2412. Immediate bounded verification found the misplaced FIX4 test path before regression-memory or release-gate replay.

No product source, release state, AAB authority, Play action, OPPO action, provider action, or secret boundary changed. The correction restores REG-2374's original two gates and adds the now-existing FIX4 behavioral test only under a hunk anchored by the unique REG-2412 identifier.
