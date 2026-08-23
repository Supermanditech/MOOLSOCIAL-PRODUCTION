# C14 C10E static gate rejected dynamic pre-render redirect

Date: 2026-08-08

Regression:
`REG-20260808-291-C14-C10E-STATIC-GATE-REJECTED-DYNAMIC-PRE-RENDER-REDIRECT`

## Failure

After both universal and Buy qualification cycles passed twice, the C10E
static gate rejected `/app/:section` because it required `pageBuilder`
immediately after `path`. C13 intentionally inserted a redirect between them
so retired roots resolve before rendering; the same GoRoute retained its
pageBuilder and shared motion owner.

## Root cause and prevention

The checker encoded declaration adjacency from the pre-C13 router rather than
the production behavior contract. It now proves every exact Eat, Ride, Book
and Work default route is page-owned, bounds the dynamic declaration before
the next GoRoute, requires the C13 pre-render default redirect, and separately
requires the retained dynamic pageBuilder and GoRouter Back owner.
