# C17H installed-state patch unverified install-authority context rejection

After installed checksum identity passed, the first metadata patch expected `buildResult.installAuthorized` to be true. The current machine state correctly retained false in that build-result block, while the active install authority lived in the C17H scope/ticket and top-level recovery state. `apply_patch` rejected the entire multi-file patch before changing any file.

The installed r60.18 app was unaffected. The correction inventories and patches the exact current ticket execution, successor, build-result and install-result contexts separately, then parses every JSON owner.
