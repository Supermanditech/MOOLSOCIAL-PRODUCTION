# C26C switcher Back fallthrough popped destination

## Observation

The real Screen04-to-Shop test reached Shop successfully. After Mool opened, one system Back removed the overlay and the Shop route, proving Back fallthrough.

## Cause

The switcher used a nested PopScope. Its veto did not prevent existing outer route PopScope callbacks from reacting to the same failed pop. The standalone root-route test could not reveal the defect because its route was not poppable.

## Permanent prevention

- Add one `LocalHistoryEntry` when the switcher opens.
- Let system Back remove that entry and close only the overlay.
- Remove the entry safely on tap, family selection, outside tap and swipe close.
- Require a real pushed-family route test proving the destination remains mounted after the first Back.

## Resolution state

Fix active; host and APK qualification remain blocked until the real-route regression passes.
