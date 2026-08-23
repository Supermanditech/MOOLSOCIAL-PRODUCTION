# C33I background local server launch policy rejection regression

- Regression: `REG-20260815-2477-C33I-BACKGROUND-LOCAL-SERVER-LAUNCH-POLICY-REJECTED`
- Failure: the shell policy rejected the hidden persistent Python server command before execution.
- Impact: no server or process was started and no repository, browser, provider, email, Hosting or device state changed.
- Prevention: present standalone review HTML with a local file URL; use only bounded foreground test servers inside active verification commands.
