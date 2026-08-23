# C23G R03 migrated route expectation rejection

The migrated R03 test tapped the six C23 family controls but compared the
result to the older `personalMoolRootActions` default-route projection. C23
truthfully routes main family taps through `/app/social`, `/app/buy`,
`/app/eat`, `/app/ride`, `/app/book` and `/app/work`; the existing router then
owns any canonical default redirection. The mismatch rejected the pre-cycle
test. No host cycle passed and no APK authority opened.
