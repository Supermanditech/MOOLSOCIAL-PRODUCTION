# C16A static gate interpolated-test-name false rejection

## Incident

The first C16A static gate rejected three coverage-name tokens even though the
focused test had passed all 2/3/4-action cases. The Dart source generates those
names from `$actionCount`; literal expanded names exist only in test output, not
in the source file inspected by the static gate.

## Root cause and prevention

The checker searched runtime-expanded display strings in source. It now proves
the explicit `const [2, 3, 4]` case set and the single interpolated test-name
source token. Static gates distinguish generated runtime labels from literal
source ownership.
