# C09 Screen 04 rewrite first failure

Date: 7 August 2026

The first standalone run of the rewritten Screen 04 conformance file passed 23
tests and failed three test-authoring assertions:

1. Mool -> Buy -> Back was expected to jump directly to Social even though the
   intended stack correctly returns to first-class Mool Home first.
2. The parameterized Social subaction loop pumped the same app widget type
   without a unique key/unmount boundary, so state from one initial subaction
   could survive into the next case.
3. The containment test guessed `screen04-feed-workbench` instead of reading
   and asserting an existing exact Feed owner.

REG-20260807-141 through REG-20260807-143 retain these failures. Test fixes
follow actual stack depth, isolate every parameterized app instance and copy
existing owner keys from source before assertion.
