# C09 first compile failure

Date: 7 August 2026

The first focused Flutter cycle stopped during compilation because the new
Mool Home header declared its parent `Row` const while containing Flutter's
non-const `Semantics` constructor. All five selected test files failed to load
from the same single source error; zero assertions ran. No APK, install or
device state changed.

REG-20260807-134 retains this failed cycle. Mixed semantic/const subtrees now
keep the parent non-const and apply const only to eligible leaf widgets; the
same focused compilation must pass before broader regression.
