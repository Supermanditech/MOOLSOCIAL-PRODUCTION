# C22D overlay outer-pixel rejection — 2026-08-08

The first hit-testable C22D overlay reduced the bottom-navigation layout height to the unchanged global rail, but the six-family raw-RGBA gate measured `[254,247,255]` outside the capsule cluster where the destination pixel was `[36,96,128]`. The same rejection occurred for Social, Buy, Eat, Ride, Book and Work. No device/build action followed. REG-20260808-531 requires exact rendered destination pixels outside and between capsules before C22D can close.
