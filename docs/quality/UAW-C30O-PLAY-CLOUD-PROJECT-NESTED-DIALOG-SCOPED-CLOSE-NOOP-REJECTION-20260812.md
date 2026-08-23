# C30O Play Cloud-project nested-dialog scoped Close no-op rejection

Date: 2026-08-12

## Observed mistake

The Close button scoped to the `Existing Google Cloud` dialog returned without an exception, but a fresh snapshot still showed the same nested dialog open and active.

## Root cause

The Play Console nested project picker did not commit the scoped Close interaction even though the browser action completed without an API error.

## Prevention

- Do not repeat the same Close interaction.
- Use the already-open dialog's bounded search control with the exact Dev project number as a distinct read-only path.
- Require a fresh snapshot before treating any dialog action as effective.

## Retained evidence

The before-and-after Browser snapshots retain the unchanged nested dialog. No external write occurred.
