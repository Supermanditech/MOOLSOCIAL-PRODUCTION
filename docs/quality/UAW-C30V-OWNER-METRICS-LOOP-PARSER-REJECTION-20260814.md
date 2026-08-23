# C30V owner-metrics loop parser rejection

Date: 2026-08-14
Successor: r60.47 recovery

## Incident

A read-only PowerShell command intended to report exact C30U owner path, line, byte and SHA-256 metrics failed at parse time because the materialized `foreach` expression was missing its closing statement-block brace.

The rejected command executed no owner read and made no repository, Google Play or OPPO mutation.

## Prevention

Use a simple statement-form `foreach` that appends rows to a ticket-specific collection, with the loop closed before any formatter pipeline. Parse the command structure visually before execution and keep missing-owner handling outside the row expression.
