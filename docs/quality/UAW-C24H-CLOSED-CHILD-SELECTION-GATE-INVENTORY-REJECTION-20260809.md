# C24H closed child-selection gate inventory rejection

Date: 2026-08-09
Regression: `REG-20260809-750-C24H-QUALIFIER-INCLUDED-CLOSED-CHILD-SELECTION-GATES`

C24H preflight invoked the historical C24C gate after C24H became the selected
scope. C24C correctly rejected because its own ticket was no longer selected.
The C24H gate inventory had conflated replaying every child focused test with
replaying phase-specific child-selection gates.

C24H must retain all child focused tests and complete affected/protected
suites, while its gate list contains only the cumulative and permanent gates
valid under selected C24H. Historical child gates remain unchanged and
preserved as their own completion evidence.

The C24H contract now retains all 38 child/affected test owners plus both
protected test manifests and uses 13 cumulative/permanent gates that are valid
under the selected C24H scope.
