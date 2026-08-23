# C29O guessed SharedSession owner-path rejection

Date: 2026-08-11
Ticket context: `UAW-PERSONAL-MVP-SOCIAL-END-TO-END-ACTION-TRUTH-AND-ACCESSIBILITY-C29O`

## Rejected attempt

A read-only command guessed `apps/mobile/lib/shared/shared_session.dart`. That
path does not exist. The failed result is not evidence for the Social data
owner and caused no product, provider, device, release or scope mutation.

## Permanent prevention

- Declaring files are resolved from `rg --files` plus an exact class-symbol
  search before they are opened.
- A remembered class name never implies a filename or directory.
- Only the returned literal owner path is admitted into the audit.
