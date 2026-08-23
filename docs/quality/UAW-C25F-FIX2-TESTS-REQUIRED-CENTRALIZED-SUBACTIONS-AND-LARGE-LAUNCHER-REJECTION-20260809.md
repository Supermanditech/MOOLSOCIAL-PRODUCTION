# C25F Fix2 predecessor centralized-subaction contract rejection

- Date: 2026-08-09
- Status: registered before migration

The Fix2 suite retained the earlier contract where Eat, Ride, Book and Work subactions were selected inside the connected MoolSocial chooser. C25 deliberately makes that chooser main-domain-only and keeps all exact subactions on each destination rail. It also replaces the 164 × 56 launcher with the compact control.

The migration will preserve every exact route, non-default Back state and active-ride safety assertion while changing only the source of taps: compact MoolSocial for main domains and family-local keys for subactions.
