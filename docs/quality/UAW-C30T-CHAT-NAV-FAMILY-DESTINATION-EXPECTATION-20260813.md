# C30T Chat navigation family-destination expectation regression

## Observation

The updated Chat navigation test opened the connected Mool family menu, selected Social, and then expected the separate Personal Mool home screen. The product correctly navigated to Social.

## Root cause

The test conflated the Mool launcher control with the family destination selected inside its menu.

## Permanent prevention

- Assert the owner associated with the exact selected menu action.
- Selecting Social must assert the Social screen.
- Assert the Personal Mool root only after invoking its dedicated home action.
