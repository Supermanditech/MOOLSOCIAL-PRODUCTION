# C24F main-destination URI page-key revisit rejection — 2026-08-09

Same-family replacement prevented query-only stacks but did not eliminate the
collision. The complete Screen04 cycle left the original Social destination in
history, crossed Buy, Eat, Ride, Book and Work, then validly revisited the exact
same Social URI. `moolMainDestinationPage` used the URI itself as its page key,
so the two distinct navigation entries collided.

The correction uses GoRouter's navigation-entry page key. The URI continues to
own destination and subaction truth; it is not a unique history-entry identity.
The exact six-family revisit and Back matrix must pass before either protected
seal is eligible.
