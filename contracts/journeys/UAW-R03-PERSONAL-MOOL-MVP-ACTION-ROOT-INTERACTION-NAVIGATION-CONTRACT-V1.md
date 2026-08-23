# UAW-R03 Personal Mool root interaction and navigation contract

Version: 1
State: direct native Flutter V2 interaction authority for R03

## Stable hub

The Personal Mool root is a single shared route at `/app/mool`. It renders six
main actions in this exact order: Social, Buy, Eat, Ride, Book and Work. Chat is
a global edge action, not a seventh Mool action. Standalone Pay is absent.

The machine mirror is
`config/mvp-personal-mool-root-interaction-v1.json`. Its R01 source projection
SHA-256 must remain exact.

## Tap contract

- One tap on Social, Buy, Eat, Ride, Book or Work pushes the existing exact
  action route. Buy receives only the exact allowlisted `/app/mool` return;
  arbitrary return-route injection remains rejected.
- System/gesture Back from that pushed route returns to the same Mool root.
- Visible Back pops to the preserved caller when one exists; a direct/deep
  open returns safely to the last permitted primary section or Social.
- One tap on Chat opens the existing global inbox with `/app/mool` as its
  explicit safe return.
- Duplicate taps cannot create a second owner or local capability grant.

## Motion and orientation

- Mool remains the visually stable centre/identity.
- Six actions arrive with finite directional opacity/translation/scale over a
  240 ms owner; no rotation, looping or fabricated loading is permitted.
- Existing card press acknowledgement may run for 160 ms.
- Reduced motion renders the final state immediately while retaining the same
  semantics, focus ownership and navigation result.

## Fitment and accessibility

All actions have stable keys, semantic button labels and at least 44x44 tap
owners. The root must fit 320x568 through 430x932, safe areas and supported text
scales without horizontal overflow. The screen owns one clear heading and a
separate global Chat label.

## Boundary

This contract exposes navigation only. It does not activate any vertical,
workspace, provider, payment or backend capability and does not alter accepted
Social or Buy presentation.
