# C30T pre-AAB Feed plain-media open dead tap

The source audit proved that a plain public Feed image does not enter sign-in,
but it also owns no tap completion. A visible first content tap therefore ends
without opening the post or media.

This `mvp_required` successor reuses the existing native Social sheet and media
preview owners to open an accessible zoomable public media view. It adds no
route, screen, backend or provider owner. Missing-media recovery, Back return,
compact/large-text fitment and zero authentication/write side effects are
mandatory. No AAB, upload, install, cloud or device mutation is authorized.

## Source implementation result

Plain post media is now an explicit accessible tap target. It opens the current
image in a native `InteractiveViewer` sheet with a `1x–4x` zoom range, clear
public-photo copy and exact Back return to the Feed card. It does not request
authentication or invoke any interaction gateway.

Focused Feed/Create verification passed `30/30`, including exact guest auth
state, zero interaction writes and `320x568` at `140%` text scale. No route,
route-level screen, backend owner, build, AAB, cloud or device state changed.
Live Play acceptance remains pending a future separately authorized candidate.
