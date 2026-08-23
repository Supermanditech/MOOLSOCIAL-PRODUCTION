# C30T Firestore index root-path assumption

- Regression: `REG-20260813-1981-C30T-FIRESTORE-INDEX-ROOT-PATH-ASSUMPTION`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Result: index lookup rejected as zero evidence.

The author-query audit assumed the standard Firestore index filename was at
repository root. The retry must locate the exact configured index owner before
checking author/public/sort fields.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
