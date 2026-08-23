# UAW-R28 FMCG Manufacturer pilot routing dependency hold

Date: 6 August 2026
Ticket: `UAW-R28-FMCG-MANUFACTURER-PILOT-ROUTING-REFERENCE`
State: `DEPENDENCY_HELD_NOT_SELECTED_NOT_EXECUTING`

## Disposition

R28 remains `mvp_supporting`, but it is explicitly held without
`manufacturer_pilot_approval`. Only a separately approved product-master,
verified pack, eligible Wholesale offer, incoming order decision and dispatch
pilot may open. Manufacturing ERP, procurement, raw materials, machinery,
growth and broad B2B remain excluded.

Repository inventory confirms the exact bounded shape and the planning
disposition `bounded_launch_pilot_dependency_held`, but found no separate pilot
approval, enabled participant, product/pack set, commercial version or active
capability publication. Existing Manufacturer fixtures and screens cannot
become that approval.

No source, HTML reference, pilot/capability data, backend, build, APK or device
action was performed for R28. The ticket will be reassessed only after an exact
pilot approval is recorded.

Next child by manifest order for reference disposition:
`UAW-R29-RESTAURANT-DHABA-CAFE-ROUTING-REFERENCE`.
