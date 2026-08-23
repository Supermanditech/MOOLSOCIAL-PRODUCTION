# C16B isolated Screen 04 main-action loop Eat-root rejection

## Incident

The entire `screen04_universal_v2_conformance_test.dart` file was replayed by
itself. The same single case failed: in `every Mool main action and Social
subaction stays visible and exact`, the repeated Mool main-action loop did not
find `mvp-action-root-eat` after the Eat tap. All other cases in the file passed.

The isolated reproduction proves the combined-run failure was not merely test-
file concurrency. No build, device or runtime mutation occurred.

## Root cause and prevention

Root cause remains under bounded diagnosis. C16B must reconcile the loop's
actual tapped global action, router location and rendered destination owner
before choosing whether production or test ownership is wrong. No source fix is
allowed from the missing-key symptom alone; the corrected owner must preserve
Social, Mool, Eat, Back and global-rail behavior and pass both the isolated file
and focused navigation coverage.
