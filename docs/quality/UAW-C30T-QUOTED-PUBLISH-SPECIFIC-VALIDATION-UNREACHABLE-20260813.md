# C30T quoted-publish specific validation was unreachable

- Regression: `REG-20260813-1960-C30T-QUOTED-PUBLISH-SPECIFIC-VALIDATION-UNREACHABLE`
- Date: 2026-08-13
- Scope: C30T Repost and Share source ticket; no deployment authority.

## Incident

An empty quoted publish was safely rejected, but generic empty-post validation
ran first. The intended `Add your thoughts` recovery contract could not be
reached, causing one of 508 backend tests to fail.

## Required prevention

The optional quoted-post identity and its exact empty-thoughts rule are checked
before generic content-format validation. Both rejection layers remain covered.

This record creates no build, upload, install, deployment or device authority.
