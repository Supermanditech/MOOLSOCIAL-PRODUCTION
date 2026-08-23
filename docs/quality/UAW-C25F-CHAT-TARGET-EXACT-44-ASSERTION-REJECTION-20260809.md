# C25F exact 44 px Chat assertion rejection

- Date: 2026-08-09
- Status: registered before focused test retry

The first C25F shortcut test required an exact 44 × 44 rendered size. Material AppBar correctly allocated a 48 × 48 interactive slot around the shortcut, satisfying and improving the 44 px minimum. The exact-size assertion rejected compliant production behavior.

The corrected test asserts both dimensions are at least 44 px.
