# Temporary navigation prototype action-count field-order assumption

## Observation

The first source-contract run for the connected glass dock passed every required literal check but returned `directActions=0` because the counting regex assumed a property order not used by the prototype action objects.

## Cause

The validation expression coupled the semantic action count to incidental JavaScript object formatting. The production data remained present and the prototype JavaScript syntax gate passed.

## Permanent prevention

- Count direct action records using a verified stable signature from the actual action object shape or parse the JavaScript data model structurally.
- Do not interpret a property-order regex miss as product-data loss.
- Keep JavaScript syntax, literal UI contracts and semantic collection counts as separate assertions so a checker failure identifies its true layer.

## Resolution evidence

The corrected source contract must count the verified direct-action object signature and report six families, eighteen direct actions and six category sets before browser review.
