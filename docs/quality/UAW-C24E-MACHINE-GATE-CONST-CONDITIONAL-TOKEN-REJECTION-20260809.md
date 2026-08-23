# C24E machine-gate const/conditional token rejection — 2026-08-09

The first C24E source-gate run rejected three guessed syntax tokens: empty-state
keys inherit constness from their parent widgets and therefore use `key: Key`,
while Doctor's `Available today` title is one branch of a conditional.

The production owners and focused tests were already passing. The gate is
corrected to bind the exact formatted literals. This rejected invocation counts
as no qualification cycle; build and install remain closed.
