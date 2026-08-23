# C30F Watch top-logo/content-attribution selector conflation rejection

- Regression: `REG-20260812-1379-C30F-WATCH-TOP-LOGO-CONTENT-ATTRIBUTION-SELECTOR-CONFLATION-REJECTION`
- Date: 2026-08-12
- Rejected assertion: every clickable native node labelled `YouTube` was treated as a removed top-header logo.
- Root distinction: clickable YouTube attribution on real content is required and remains allowed; only a header-region logo is removed.
- Preserved evidence: `12-watch-from-search.png` and `12-watch-from-search.xml` were captured after selecting a real Search result.
- Prevention: classify the node by bounds/region and assert Back/Search independently before accepting the Watch state.
