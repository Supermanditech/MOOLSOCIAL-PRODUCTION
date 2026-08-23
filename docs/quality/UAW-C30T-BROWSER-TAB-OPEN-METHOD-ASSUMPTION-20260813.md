# C30T browser tab-open method assumption

Date: 2026-08-13

The read-only browser fallback attempted an inferred `browser.tabs.open` call. The connected browser API does not expose that method; the call failed before opening or changing any tab.

Permanent prevention: read the complete connected-browser documentation before retrying, reuse an existing tab binding where available, and never infer browser-client method names.
