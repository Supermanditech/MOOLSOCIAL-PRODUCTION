# C29N composer publish CTA infinite-host-width rejection

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1235-C29N-COMPOSER-PUBLISH-CTA-INFINITE-HOST-WIDTH-REJECTION`

The C29N protected batch passed 117 tests before the connected-chooser Create
journey exposed one layout defect. The new header `FilledButton` inherited an
unbounded horizontal constraint and attempted to create a physical shape with
infinite width. No qualification artifact or runtime mutation occurred.

The publish CTA now owns a finite compact width and minimum accessible height.
The normal keyboard-safe composer, compact fitment matrix and connected-chooser
journey all remain protected gates.
