# UAW C33F OPPO UIAutomator trailing-status parse failure

The first sanitized app-only hierarchy reader attempted to parse the complete `/dev/tty` response as XML. Android appended `UI hierarchy dumped to: /dev/tty` after the closing hierarchy element, so `XmlDocument` rejected the mixed payload. The command failed before producing its intended bounded node summary.

No private account chooser was opened or inspected by this attempt. The returned app-owned hierarchy contained only the MoolSocial Google-sign-in failure sheet and confirmed the existing release blocker.

Every later hierarchy reader must extract exactly from the XML declaration through the closing `</hierarchy>` marker before parsing, restrict nodes to `package=com.moolsocial.app`, redact identifier-like text before output, and reject missing or multiple boundaries.
