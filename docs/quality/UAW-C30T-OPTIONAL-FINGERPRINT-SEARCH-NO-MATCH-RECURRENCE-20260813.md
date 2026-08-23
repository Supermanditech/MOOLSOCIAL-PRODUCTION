# C30T optional fingerprint search no-match recurrence

Date: 2026-08-13

An exact search for the stale live Android App Links certificate fingerprint returned the valid no-match exit 1. Because that query was unnormalized inside a parallel batch, it aborted the aggregate diagnostic.

The retry is sequential and explicitly records match absence. No product, backend, provider, device, AAB, Play or communication state changed.
