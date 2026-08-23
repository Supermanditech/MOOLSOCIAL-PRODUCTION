# C30T PowerShell foreach-pipe parser second recurrence

Date: 2026-08-13
Scope: read-only C30T child-ticket status inventory

## Observed failure

A diagnostic placed a pipe directly after a `foreach` statement. PowerShell rejected the empty pipe element before returning the requested inventory, repeating the mistake already registered in REG-1682. No repository, provider, Play or device state changed.

## Prevention

All PowerShell `foreach` inventories must collect into an explicitly initialized array and pipe only the completed array. The failed command is not retried until this recurrence is registered.
