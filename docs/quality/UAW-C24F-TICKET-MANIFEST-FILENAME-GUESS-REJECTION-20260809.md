# C24F ticket manifest filename guess rejection — 2026-08-09

The first C24F preselection inspection guessed a `book-bus-home` ticket
filename. That file does not exist. Because the compound read did not stop on
the PowerShell error, later parent and scope owners were printed, but the C24F
ticket itself was not read and no selection authority was established.

No C24F mutation occurred. The retry discovers the manifest by exact ticketId,
requires one result and reads every selected owner under stop-on-error.
