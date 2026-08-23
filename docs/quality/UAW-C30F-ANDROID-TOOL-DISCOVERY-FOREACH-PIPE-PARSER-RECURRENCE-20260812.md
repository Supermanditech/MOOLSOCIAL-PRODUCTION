# C30F Android-tool discovery foreach-pipe parser recurrence

- Regression: `REG-20260812-1376-C30F-ANDROID-TOOL-DISCOVERY-FOREACH-PIPE-PARSER-RECURRENCE`
- Date: 2026-08-12
- Rejected command: the read-only tool discovery piped directly after `foreach`, producing `An empty pipe element is not allowed` before execution.
- Artifact state: the single r60.37 build already succeeded; APK SHA-256 is `09277766FC5700C886DCA4262E98611BCC299CBE3404227DB02579058A966A6F`. It remains uninstalled and no second build is authorized.
- Prevention: assign loop output to a bounded array, then serialize the array.
