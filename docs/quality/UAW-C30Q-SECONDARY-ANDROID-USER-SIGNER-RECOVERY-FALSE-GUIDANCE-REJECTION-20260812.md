# C30Q secondary Android user signer-recovery false guidance rejection

Date: 2026-08-12

## Mistake

After proving that the owner-user installation is debug-signed, Codex
recommended creating a secondary Android user on the same OPPO to install the
Play-signed C30Q package while preserving the owner user's data.

That guidance was wrong. Android multi-user isolates per-user app data and
installed/enabled state, but package code and signing identity are managed for
the package at the device level. A second user cannot hold a differently signed
APK for the same package while the debug-signed `com.moolsocial.app` remains on
the device. The Play installation would encounter the same signer conflict.

## Detection and impact

The error was caught when the founder asked how to create the secondary user,
before any user/profile creation, account sign-in, Play retry, installation,
uninstall or data mutation occurred.

## Permanent prevention

Never propose Android secondary users, guest users, work profiles or cloned-app
features as a workaround for a package-signature mismatch. Treat signing
identity as device-global for an installed package. For the same package, the
lawful choices are a compatible signing lineage, complete package removal
followed by the newly signed install, or a separate physical device on which
the package is absent. Any removal remains separately founder-gated because it
clears the existing app data.
