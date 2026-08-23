# Temporary prototype founder category-requirement drift recurrence

Date: 2026-08-09

The REG859 correction removed category selection to solve top-control thumb
reach. That also removed the founder-required YouTube-style visible categories,
returning Food, Travel, Care and Work to Homes that did not support the explicit
All/category discovery model shown in the OPPO YouTube reference.

Root cause: visible categories, zero lost content height, one-handed operation
and direct outcomes were treated as alternative designs instead of simultaneous
requirements.

Correction contract: Social, Shop, Food, Travel, Care, Work and Videos each
show a horizontally scrollable category strip at the top of the first media
surface. It is absolutely overlaid in a reserved safe artwork region and adds
zero normal-flow height. All is selected by default and already shows direct
transaction-ready content. Customers may tap a chip, but a horizontal thumb
swipe anywhere on the hero changes category without reaching the top. Category
selection never becomes a prerequisite for tapping a product or service.

No Flutter source, accepted screenbook, APK, installed OPPO state or protected
runtime was changed by this temporary-HTML rejection.
