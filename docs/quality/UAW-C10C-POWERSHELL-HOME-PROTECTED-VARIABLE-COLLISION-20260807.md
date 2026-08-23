# C10C PowerShell protected HOME variable collision

A read-only source inspection assigned content to `$home`. PowerShell variable names are case-insensitive, so this attempted to overwrite the protected read-only `$HOME` variable and terminated the command. Task data now uses explicit names such as `$c10cHomeDeliveryLines`; protected environment and automatic variable names are never repurposed.
