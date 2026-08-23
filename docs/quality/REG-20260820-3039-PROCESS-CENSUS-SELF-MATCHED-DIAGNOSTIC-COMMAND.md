# REG-20260820-3039 process census self-matched diagnostic command

## Observed failure

The frozen-checkout process census reported one repository writer and one
source command even though no independent writer or source command was in
flight. The result is rejected as cutover evidence.

## Root cause

The census inspected every process whose command line contained the repository
path, including its own PowerShell process. Its own command text also contained
the writer and source regular expressions, so both counters self-matched.

## Impact

- no repository, provider, build, Play, OPPO, account or device state changed;
- no source or external command was executed;
- the emitted `1/1` counters are not accepted as evidence.

## Prevention and authorized retry

Exclude the current process ID before applying command-line classifiers and
emit only the two bounded counts. Do not reuse the self-inclusive census.
