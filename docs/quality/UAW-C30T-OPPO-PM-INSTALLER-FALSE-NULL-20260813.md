# C30T OPPO package-list installer false null

Date: 2026-08-13

The bounded `pm list packages -i com.moolsocial.app` query returned `installer=null`. The package-specific `dumpsys package com.moolsocial.app` record in the same reconciliation reports the authoritative field `installerPackageName=com.android.vending`.

Permanent prevention: use only the exact package-specific `installerPackageName` field on this OPPO and treat the package-list projection as non-authoritative when it returns null.
