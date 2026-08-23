# REG2682 — Full rejection-object parity was a false failure

## Outcome

The state rejection object includes four explicit action-count fields that the aggregate rejection object intentionally omits. Comparing the complete serialized objects therefore returned a false parity failure. This is not a C34F candidate-state defect.

## Prevention

Compare the documented shared rejection fields by name and compare `actionCounts`, `machineState`, and `releaseAuthorities` independently. No successor or external action is authorized by this diagnostic correction.
