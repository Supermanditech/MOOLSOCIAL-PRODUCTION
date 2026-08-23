# C25E predecessor navigation test assertions — rejection

Date: 2026-08-09

The existing vertical suites still target presentation removed by founder direction: `mool-home-launcher`, Home-level subaction tiles such as `mool-home-buy-shop`, direct actions inside the connected popup, and assertions that destination-local rails are absent.

The tests must be migrated one file at a time to the compact `mool-compact-launcher`, main-only domain keys and destination-local action keys. Cart, order, payment, provider, session, recovery, lifecycle and Back behavior assertions must not be weakened.
