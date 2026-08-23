# C17C regression entry referenced a future test

Date: 2026-08-08

The first memory-gate run after registering the Social wrapper defect rejected
entry 350 because its `gates` array named the planned C17C focused test before
the C17C scope gate had authorized and created that file. No memory pass or
C17C runtime authority was claimed. Entry 350 is corrected to reference only
the existing permanent memory checker. The future test can be added to a gate
only after it exists.
