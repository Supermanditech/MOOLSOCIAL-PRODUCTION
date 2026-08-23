# C33I in-app browser local-file URL policy block

Date: 2026-08-15
Ticket: `UAW-C33I-SCREEN03-PASSWORDLESS-EMAIL-LINK-REFERENCE-SUCCESSOR`

## Failure

The connected in-app browser rejected automated navigation to the local Screen 03 `file://` proposal under its URL safety policy. No navigation, repository mutation or external action occurred.

## Root cause

The browser-control surface does not permit model-driven navigation to this local-file URL.

## Permanent prevention

Do not retry, bypass or substitute another browser-control surface after this policy block. Verify the additive local proposal through immutable-source comparison and repository-contained static assertions, and provide the exact local path for founder-controlled review.
