# UAW C30V minified browser-client search output truncation — 2026-08-14

A source search for browser upload APIs matched the browser client's minified generated bundle line and returned truncated output. The lookup established that the page API supports `waitForEvent("filechooser")`, but the exact chooser method still requires a small bounded interface extraction.

No browser mutation or Play upload occurred. Future inspection of a minified owner must extract only the exact named API-manifest interface substring with a strict character bound; never emit full matching lines.
