# Post-C32P backend package-root path assumption

Date: 15 August 2026
Regression: `REG-20260815-2266-POST-C32P-BACKEND-PACKAGE-ROOT-PATH-ASSUMPTION`

The additional read-only backend audit attempted `backend/package.json`, which does not exist. No package command ran and no backend file or external service changed.

The retry must first discover exact package manifests with a bounded `rg --files backend -g package.json`, then use only their declared local test scripts.
