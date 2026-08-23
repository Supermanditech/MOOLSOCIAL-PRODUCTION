# C23G ticket-manifest filename assumption rejection — 2026-08-09

## Observed rejection

During C23E1 sealing, the next C23G ticket path was guessed from its role and
gate label. The file did not exist, the read-only batch stopped, and no ticket
or scope state changed.

## Permanent prevention

Inventory the bounded `config/*c23*.json` candidates, inspect their exact
`ticketId`, and use only the literal owner returned by that inventory. Ticket
hierarchy and gate wording do not imply a filename.
