# Temporary navigation prototype persistent toolbar zero-height rejection

Date: 2026-08-09

The REG857 revision removed the family heading, lead and full search field, but
the replacement Search, Chat and category toolbar still occupied permanent
vertical space above the Shop discovery card. Founder phone-scale evidence
showed that the row and its surrounding separation continued to reduce the
visible customer-content area.

Root cause: the correction minimized permanent chrome instead of satisfying
the literal requirement that family-home utilities consume zero vertical
layout height.

Correction contract: the first discovery surface begins immediately beneath
the existing global main-action rail. Search, Chat and Filter remain 44px
tappable but are positioned inside a visually reserved safe overlay region of
that surface. Filter choices appear only in a transient dismissible overlay;
selecting a category or tapping outside closes it and restores the complete
content view. No family-home utility or category row may participate in normal
vertical layout flow.

No Flutter source, accepted screenbook, APK, installed OPPO state or protected
runtime was changed by this temporary-HTML rejection.
