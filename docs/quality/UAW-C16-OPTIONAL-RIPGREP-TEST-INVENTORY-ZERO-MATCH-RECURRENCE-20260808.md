# C16 optional ripgrep test-inventory zero-match recurrence

## Incident

An optional test inventory searched for the old local-rail distribution,
scroll and constructor tokens. Ripgrep found no matches and returned its normal
zero-match exit `1`, but the command boundary did not explicitly classify that
exit and therefore surfaced as failed. No mutation occurred and the output is
discarded until a classified retry.

## Root cause and prevention

The existing C16 zero-match rule was not applied to this new optional query.
Every subsequent optional ripgrep call captures the native exit immediately,
accepts `0` as matches and `1` as a declared zero-match result, and rejects only
values above `1`.
