# UAW-CURSOR-UI-SHOP-LOCATION-ADDRESS-V1-20260828

State: `founder_authorized_journey_audit`

- Work ID: `shop-location-address-v1-20260828`.
- Branch: `work/cursor-ui/shop-location-address-v1-20260828`.
- Baseline: `9d5b31765e65f72d501945b8f32cc37a407b67f5`.
- Actor: personal shopper using the Shop workspace.
- Scope: `mvp_required`.

Customer outcome: choose Home or Work, request/add/edit an address, recover
from invalid or cancelled input, save/select the final address, and return to
the exact prior Shop state with clear selected and pressed navigation feedback.

Smallest complete implementation:

1. Inventory and reuse the existing native V2 address session, sheets, forms,
   global profile, bottom rail and Shop subaction owners.
2. Complete Home, Work, Request an address and Add/Edit address paths through
   success, validation, error, cancel and Back recovery.
3. Standardize typography, shapes, spacing, hit targets, content proportions,
   focus/pressed/selected states and responsive Redmi fitment.
4. Use finished customer-facing copy only.
5. Replay every tap and two affected regressions, then run the complete Buy
   suite twice before one uniquely versioned Redmi review APK.

Explicit exclusions: backend/API/Firebase work, new address persistence
services, Android/iOS configuration, OPPO/runtime package changes, unrelated
Shop redesign, and every already-approved surface outside this successor.

Dependencies: approved Shop landing source, existing Buy session/address
owners, approved shared global profile/navigation behavior, and the current
CursorUiReview build isolation.

The founder accepts every baseline surface except this location/address and
navigation-feedback successor. Stop after the full journey is shown on Redmi;
do not start another Shop destination.

Audit outcome: the saved-address chooser, request form and add form already
exist and are retained. The required delta is customer-facing redesign,
truthful request-link completion, visible Shop selected/pressed feedback and
one thin in-memory `updateAddress` operation so Home/Work edits complete
without adding a service, API or persistence owner.
