# C30O Play signing declaration screenshot-coordinate no-op rejection — 2026-08-12

## Disposition

Rejected no-op form input. The programme-policy declaration remains checked, the Play app signing declaration remains unchecked, and the form was not submitted.

## Mistake

A screenshot-coordinate click intended for the visible Play app signing declaration did not change its unchecked state.

## Root cause

The captured coordinate did not resolve to the checkbox hit target even though the square was visible.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Treat the unchanged fresh screenshot as authoritative.
- Extract only the exact visible Play signing checkbox accessibility match.
- Click that refreshed element once and verify its state immediately.
