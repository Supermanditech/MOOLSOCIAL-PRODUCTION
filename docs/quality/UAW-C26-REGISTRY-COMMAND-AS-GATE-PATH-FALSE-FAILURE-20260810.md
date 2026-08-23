# C26 registry command-as-gate-path false failure

## Observation

The regression-memory checker rejected REG873 because its `gates` array
contained the command label `flutter analyze`, which is not a repository file.

## Cause

An ad hoc validation command was confused with the registry's required
repository-relative machine-gate owner.

## Permanent prevention

- Every `gates` value must resolve to an existing repository-relative file.
- Record direct command invocations in evidence prose.
- Add a command to `gates` only through a real checked-in wrapper path.

## Resolution evidence

REG873 now references only the permanent regression-memory wrapper, while its
evidence document retains the focused analyzer requirement.
