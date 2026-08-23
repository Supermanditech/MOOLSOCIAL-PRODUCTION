# REG2659 — C34C post-seal build-fixture compound patch context mismatch

C34C had already sealed 1,288 source files, completed two identical full source cycles and passed its distinct `preprompt` phase in both PowerShell hosts. Codex then created two non-secret fixture copies and attempted one combined state/aggregate patch to simulate the postinput `build` phase. The patch assumed three runtime-configuration fields were adjacent; the generated state fixture used a different exact layout, so `apply_patch` rejected the entire operation without changing either fixture.

No hidden value was requested or accessed. No wrapper, Flutter build, AAB, Play, OPPO, deployment, email or SMS action occurred. The detailed and aggregate candidate counts remain `0/0/0/0`.

The failed patch is nevertheless a new post-seal tooling mistake and repeats the exact-context class preserved by REG2657. C34C is therefore rejected. The successor must create, inspect, patch, parse and execute every preprompt/postinput positive and negative fixture before generating its source manifest. After sealing, no fixture creation or mutation is permitted.
