# C23E direct routing preselection

C23E reuses the journey router's existing `context.push` behavior and the exact
C23 route matrix. The change is one thin callback wiring from Mool Home; it adds
no route, screen, backend, state or action. Every Home target is direct, with no
family expansion step. Build/install remain closed.
