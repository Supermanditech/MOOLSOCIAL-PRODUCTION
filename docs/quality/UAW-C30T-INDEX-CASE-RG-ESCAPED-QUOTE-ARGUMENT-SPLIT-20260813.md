# C30T index case ripgrep escaped-quote argument split

- Regression: `REG-20260813-1977-C30T-INDEX-CASE-RG-ESCAPED-QUOTE-ARGUMENT-SPLIT`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Result: incomplete search rejected as evidence.

The backend dispatch search mixed JavaScript escaping with PowerShell parsing
for quoted `case` literals. Ripgrep interpreted parts as paths and reported
file-not-found errors. The retry must use PowerShell single-quoted literal
patterns.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
