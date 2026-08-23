# C34F pre-sealed Internal Testing browser qualification

Date: 2026-08-17 IST

State: `qualified_fresh_known_MoolSocial_Internal_testing_route_zero_C34F_Play_writes`

C34F is bound to Google Play Console Testing > Internal testing for package
`com.moolsocial.app` only. The workflow must open one fresh tab at the known
MoolSocial Internal Testing route in the already signed-in Chrome session. It
must not call or emit `openTabs()`, browser history, unrelated tab metadata,
raw authenticated URLs, query strings, fragments, account or tester data,
private links, cookies, storage or session values.

After opening the fresh tab, only the query-free allowlisted Play host/path,
MoolSocial application heading, Internal testing heading, track status,
release name, version name/code, artifact hash/bytes and action counts may be
read. The browser runtime must match internally and return no raw URL object.

This qualification is bound to regression registry 2,646 / SHA-256
`5DB74D0BDBEAAB4B9A57D414CA56C90906E368033AF46E429010ADAE7B743C9B`.
It incorporates `REG-20260813-1863-C30T-CLOUD-TAB-URL-QUERY-EXPOSURE` and
`REG-20260817-2664-C34E-PREUPLOAD-RAW-CHROME-TAB-URL-QUERY-EXPOSURE-RECURRENCE`.

No release draft, file attachment, upload, activation, promotion, OPPO action
or other Play write is performed by this pre-seal qualification.
