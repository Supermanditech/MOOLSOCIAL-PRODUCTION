# UAW C33K Firebase Email/Password provider save rejected

Date: 2026-08-15

Regression: `REG-20260815-2520-C33K-FIREBASE-EMAIL-PROVIDER-SAVE-REJECTED`

## Finding

After both Email/Password and passwordless Email Link switches were visibly
checked, the single authorized Save submission returned the visible Firebase
console message `Error updating Email/Password`. The dialog remained open and
no successful provider-table readback existed, so the action count remains
zero and the write is not claimed.

No secret, private identity payload or email address was inspected or entered.

## Resolution rule

- Never count a submitted external form as a write without authoritative
  post-submit state.
- Re-read the provider table after leaving the failed dialog.
- Inspect only safe project/configuration prerequisites and the visible console
  state before deciding whether a fresh retry is valid.
- Do not obtain or print CLI access tokens to bypass the console failure.

No Hosting, email, build, Play or device action was performed.

## Resolution

The founder explicitly refreshed the Firebase console page. After regression
and C33K prewrite gates were replayed, one fresh submission succeeded. The
provider table then showed Email/Password, Phone and Google, and the unchanged
Email/Password editor read back both switches as checked. The rejected
pre-refresh submission remains uncounted; the successful post-refresh provider
write is counted exactly once.
