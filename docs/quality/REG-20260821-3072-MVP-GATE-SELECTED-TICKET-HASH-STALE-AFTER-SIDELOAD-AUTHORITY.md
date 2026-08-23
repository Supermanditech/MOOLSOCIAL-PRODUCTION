# REG3072 — MVP selected-ticket hash stale after sideload authority update

- Date: 2026-08-21
- Status: registered before retry

The MVP scope gate rejected execution because the founder's exact sideload
authority was added to the selected FIX5 ticket without refreshing the pinned
`selectedTicketAssessment.manifestSha256`. No build, device or external action
followed.

Prevention: after every authorized selected-ticket mutation, recompute and pin
its exact manifest hash and update only the corresponding execution scope before
rerunning the MVP gate.
