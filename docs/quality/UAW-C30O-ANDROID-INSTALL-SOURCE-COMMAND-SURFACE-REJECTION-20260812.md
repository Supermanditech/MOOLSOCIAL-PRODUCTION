# C30O Android install-source command-surface rejection

Date: `2026-08-12`

State: `REJECTED_READ_ONLY_COMMAND_NO_DEVICE_MUTATION`

The first C30O installed-package identity preflight invoked
`cmd package get-install-source com.moolsocial.app` on OPPO CPH2375 Android 13.
This device command surface returned exit `255`, so the compound identity
summary was rejected and none of its partial output was accepted as evidence.

The command was read-only and did not launch the app, install, uninstall,
clear data, downgrade or otherwise mutate the device. The exact OPPO remained
connected and r60.40 remained installed.

Permanent prevention: discover installer ownership only through a command
surface already supported on the exact device. For this candidate, use the
bounded `dumpsys package com.moolsocial.app` installer metadata or
`pm list packages -i com.moolsocial.app`, check the native exit immediately,
and accept only one exact package row. Never infer Play recognition from an
unsupported command or from package/signature identity alone.
