# Post-C33C Book test inventory included PNG captures

The first Book test lookup returned twelve paths, but four were candidate
capture PNGs under `test/ui_v2/book/candidate_captures`. The directory-match
branch did not retain the `.dart` suffix condition.

REG-2311 rejects that test count. The retry must constrain `rg --files` to
`*.dart` before applying Book filename and directory filters. Capture assets
remain preserved and are not test owners.
