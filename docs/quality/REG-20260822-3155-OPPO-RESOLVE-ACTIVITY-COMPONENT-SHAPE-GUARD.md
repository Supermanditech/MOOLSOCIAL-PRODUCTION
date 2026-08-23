# REG3155 - OPPO resolve-activity component-shape guard

## Classification

Registered precondition rejection before force-stop, with zero device mutation.

## Evidence

The cold-launch wrapper resolved the installed package and then rejected the returned component because it did not start with the assumed `com.moolsocial.app/` shape. The guard executed before `am force-stop`; no launch, interaction, install, uninstall, data clear, provider action or private login occurred.

## Prevention

After registration, project the resolver result once, validate that it contains only the expected package and activity, and use the exact validated component for one separately gated cold launch.
