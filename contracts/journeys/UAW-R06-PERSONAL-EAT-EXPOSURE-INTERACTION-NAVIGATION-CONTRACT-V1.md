# UAW-R06 Personal Eat exposure interaction and navigation contract V1

Status: implementation authority for the bounded R06 successor delta
Actor: Personal user
Entry: `/app/eat` from Personal Mool

## Tap-to-tap journey

1. The user taps **Eat** on Personal Mool.
2. Eat opens with one compact header and exactly two selectable actions:
   **Order Food** and **Book Table**.
3. Tapping **Order Food** pushes `/app/eat/home` and hands control to the
   existing restaurant ordering journey.
4. Tapping **Book Table** pushes `/app/eat/table` and hands control to the
   existing table-booking journey.
5. Visible Back and system Back pop to the exact prior surface when a stack is
   available; direct/deep-link entry falls back to `/app/mool?from=eat`.
6. **Mool** is available in one tap and opens `/app/mool?from=eat`.
7. **Chat** is globally available in one tap and opens
   `/app/chat/inbox?return=/app/eat`.

## Presentation and motion

- The surface is direct native Flutter and does not copy the rejected old Eat
  prototype presentation.
- Arrival motion is finite (180–320 ms), directional and non-looping.
- Reduced-motion or accessible-navigation settings render the settled state
  immediately.
- Every action and navigation control has at least a 48 logical-pixel target,
  explicit semantics and a visible forward/back direction.
- Compact and text-scaled phones must remain usable without clipped actions or
  unreachable navigation.

## Policy boundaries

- Visible actions are exactly `order-food` and `book-table`.
- `tiffin` is not rendered, advertised or reachable from this surface.
- R06 does not remove historical routes; UAW-R12 owns route/deep-link
  containment.
- Downstream Eat screens remain existing journey owners and are not declared
  visually final by this exposure ticket.
