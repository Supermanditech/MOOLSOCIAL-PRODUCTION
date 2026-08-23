# C25F C02 global-navigation contract rejection

Date: 2026-08-09

C02 retained ten obsolete shell assertions: large destination launcher taps,
absence of destination-local actions and a second Home subaction tap. The
stable Home owner and duplicate-owner checks already passed.

The migration is bounded to navigation presentation. It must keep exact owner
continuity under menu dismissal, deep-route action availability, Ride Auto
session preservation, direct Home-origin fallback and native Back history.
The compact menu remains main-actions-only and every direct local action stays
on its destination.
