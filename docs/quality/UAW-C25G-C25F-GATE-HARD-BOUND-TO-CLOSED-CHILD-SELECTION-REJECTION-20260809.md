# C25G C25F gate hard-bound to closed-child selection

Date: 2026-08-09

## Rejection

The C25F gate required C25F to remain the current parent and scope ticket even
after C25F was lawfully completed and C25G selected. That made predecessor gate
replay impossible under host qualification.

## Recovery

The gate now distinguishes its sealed active state from the exact completed
child state. The completed branch requires the parent C25F record to be
`complete`, C25G to be the current parent/scope ticket, and runtime/build/install
authority to remain closed. All adaptive, route, motion, Social/Buy seal and
r60.23 identity assertions remain mandatory.

## Permanent rule

Reusable child gates retain strict active checks and add only an exact,
parent-bound completed replay path for their lawful successor.
