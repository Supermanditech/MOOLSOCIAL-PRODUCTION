# C30A guessed backend test path inventory rejection

- Regression: `REG-20260811-1352-C30A-GUESSED-BACKEND-TEST-PATH-INVENTORY-REJECTION`
- Date: 2026-08-11
- Result: inventory rejected and not used as accepted source evidence.

The maxResults search included the unverified path `backend/functions/test`, which does not exist. Although other matches printed, the whole command is discarded. Exact backend test owners must first be established with a bounded `rg --files` inventory before required token searches are rerun.

No product, device, backend or external mutation occurred.
