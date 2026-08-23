# REG2828 — C34L retained negative-inventory order

Date: 17 August 2026
State: registered WinPS final-inventory fixture failure; zero external action

## Mistake

The direct Windows PowerShell retained suite executed every fixture, then its
final inventory assertion failed at index zero. The new builtAt negatives run
first, but their expected labels were inserted later in the oracle array. Exit
was nonzero and no external action occurred; no reorder or retry followed.

## Prevention

Define the ordered expected-negative inventory once beside execution order, or
append each exact label at the moment its fixture runs. Assert exact count,
uniqueness, and sequence without maintaining a separately transcribed array.
