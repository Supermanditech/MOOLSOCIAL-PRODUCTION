# C13 direct default routes bypassed shared destination motion

Date: 2026-08-07

Regression:
`REG-20260807-277-C13-DIRECT-DEFAULT-ROUTES-BYPASSED-SHARED-DESTINATION-MOTION`

## Failure

The independent C10E file found the final two connected-batch failures. The
Eat-to-Work main-action switch reached Work Earn but exposed no
`moolsocial-main-destination-motion`, because the new direct action route used
an exact GoRoute builder rather than the shared main-destination page. The
reduced-motion case correctly showed no transition but still expected the
retired Work chooser key.

## Root cause and prevention

Changing `PersonalMoolActionSpec.route` preserved destination ownership but
did not automatically carry the transition wrapper previously supplied by the
dynamic root page. Eat Home, Ride Booking, Book Doctor and Work Earn therefore
use `moolMainDestinationPage` as their exact page owner. Normal motion remains
finite at 240ms; reduced motion renders the child directly. Tests assert the
real Work Earn owner and never restore the chooser.
