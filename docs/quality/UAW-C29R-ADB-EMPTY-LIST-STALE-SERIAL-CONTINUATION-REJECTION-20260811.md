# C29R ADB empty-list stale-serial continuation rejection

Date: 2026-08-11

After the founder reported OPPO connected, the first read-only command printed
an empty `adb devices -l` list but continued with the previously protected
serial `2b3e0f71`. The package metadata and package-path reads then returned
`device not found`.

Device discovery must now run alone. Every serial-scoped action is blocked
unless the exact serial appears once with state `device`; empty, `offline` or
`unauthorized` output stops the attempt. No app launch, tap, build, install,
uninstall, data clear, downgrade or protected-runtime mutation occurred.
