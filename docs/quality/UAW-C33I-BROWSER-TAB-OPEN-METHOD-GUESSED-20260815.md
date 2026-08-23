# C33I browser tab-open method regression

Date: 2026-08-15
Ticket: `UAW-C33I-SCREEN03-PASSWORDLESS-EMAIL-LINK-REFERENCE-SUCCESSOR`

## Failure

The first local-browser navigation retry invoked `browser.tabs.open(...)`, but the connected browser binding does not expose that method. The call failed before navigation. No repository or browser state was changed.

## Root cause

The tab API name was guessed after a persistent browser binding was reused without the method surface being present in the compacted task context.

## Permanent prevention

When a persistent browser binding is reused but its callable surface is not available in current context, inspect the binding's supported method names first and invoke only a verified method. Never guess a tab-open API.
