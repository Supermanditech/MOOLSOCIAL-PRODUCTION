# REG3083 — public-auth sideload rejected by YouTube-only runtime-mode gate

- Date: 2026-08-21
- Status: registered before successor implementation
- Rejected version: `1.0.0-r60.77+2026082177`

## Incident

The checksum-qualified r60.77 sideload installed successfully, but fresh launch
rendered the fail-closed update screen. The release configuration values were
present; `_runtimeModeIsValid()` rejected every live `MOOLSOCIAL_DEVICE_REVIEW`
build unless it was the YouTube public-review/private-proof profile. The newly
qualified explicit public-auth sideload profile was not represented.

## Impact

- no authentication or private login was attempted;
- the installed r60.77 candidate is retained as rejected evidence;
- Play, provider and cloud state did not change.

## Prevention

Permit non-emulator device review only for either the existing YouTube public
review contract or the explicit signed public-auth sideload contract. Require
both sideload and local-signing qualification facts, retain fail-closed
negative tests, and build a distinct successor version.
