# C30T OPPO unsupported install-source command

Date: 2026-08-13

The read-only installer reconciliation attempted `cmd package get-install-source` for `com.moolsocial.app`. The connected OPPO CPH2375 returned `Unknown command: get-install-source`; no device state changed and the result was rejected.

Permanent prevention: use the OPPO-compatible bounded query `pm list packages -i` for the exact package and parse only its installer field.
