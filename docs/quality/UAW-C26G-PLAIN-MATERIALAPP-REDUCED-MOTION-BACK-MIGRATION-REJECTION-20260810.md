# C26G plain-MaterialApp reduced-motion Back migration rejection

The first FIX2 reduced-motion test migration replaced the removed close control with platform Back. The test harness is a plain `MaterialApp` without a Router BackButtonDispatcher, so the production router-level Back listener is intentionally absent and the switcher remained visible.

The failed run is rejected. Real GoRouter-backed C26C/C26D/C26E/C26F tests retain exact system Back and destination-state proof. This router-less presentation test now uses the approved outside-tap dismissal and verifies immediate reduced-motion closure after one pump.
