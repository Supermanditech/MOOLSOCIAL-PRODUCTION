# C30T web direct unsafe-URL open rejection

Date: 2026-08-13

The live Android App Links check directly opened the asset-links and Social-link URLs before the web tool had established the official domain. Both opens were rejected as unsafe and yielded no HTTP evidence.

The retry must establish the official domain with a bounded search and then open same-origin URLs. No product, backend, provider, device, AAB, Play or communication state changed.
