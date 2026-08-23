# C30F Watch/Search return semantic-label device rejection

- Regression: `REG-20260812-1380-C30F-WATCH-SEARCH-RETURN-SEMANTIC-LABEL-DEVICE-REJECTION`
- Date: 2026-08-12
- Candidate: r60.37 / `2026081237`, installed once in place, APK SHA-256 `09277766FC5700C886DCA4262E98611BCC299CBE3404227DB02579058A966A6F`.
- OPPO evidence: `12-watch-from-search.xml` exports `Back to YouTube Home` at `[0,82][96,178]` after selecting a real `India news` Search result.
- Expected behavior: Back restores the preserved full-page Search results; therefore the native label must identify Search results, not Home.
- Disposition: r60.37 is rejected for founder acceptance. It remains installed and preserved until a separately ticketed, source-qualified and checksum-unique successor is ready. No second C30F build or install is allowed.
