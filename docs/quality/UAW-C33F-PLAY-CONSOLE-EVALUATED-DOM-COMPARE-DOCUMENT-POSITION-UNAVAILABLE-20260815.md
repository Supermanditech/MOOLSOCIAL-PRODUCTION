# UAW C33F Play Console evaluated DOM-position correction

Date: 2026-08-15

The browser-client evaluation proxy did not expose native
`compareDocumentPosition`. No certificate value was returned or displayed.
The correction is to use stable locator document order: the page headings place
the current `App signing key` section before previous and upload-key sections,
so only the first exact SHA-1 row is eligible for the authorized comparison.
