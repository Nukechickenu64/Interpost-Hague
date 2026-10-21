# Creation Charges

Vending machines start with 10 creation charges. Product catalogs are recipes,
not inventories: creating an item consumes charges rather than product stock.
Every universal creation token is consumed on insertion and adds 10 charges to
the machine's existing balance. Refills can accumulate above 10.

## Costs

The shared `creation_charge_cost()` helper assigns these tiers:

| Item | Charges |
| --- | --- |
| Handcuffs and ordinary supplies | 1 |
| Flashes, devices, grenades, and hyposprays | 2 |
| Supply boxes and PDAs | 3 |
| Guns | 4 |
| Suits | 5 |

Computer vendors start at 3 charges per device, with additional charges for
selected hardware upgrades. Antagonist uplinks use creation charges and the
same item tiers, keeping their existing role restrictions. Universal tokens
also refill an active uplink. Telecrystals remain physical teleportation
supplies; they no longer refill uplinks or function as equipment currency.
Uplinks created as equipment start empty to prevent charge duplication.
Human traitors retain their one-time plant collection of a charged fabricator;
collection is independent of the removed Leverage shop.

Cash, coins, bank accounts, payment terminals, salaries, cargo credit balances,
monetary events, and the Leverage shop have been removed. Cargo retains access
checks, requisitions, approvals, manifests, shipping, and export-request
progress without payments. Merchants retain item-for-item barter. Material,
biomass, research, electrical, and deity-power resources remain separate.

## Manual In-Game Checks

- A security vendor starts at 10; a flash leaves 8 and handcuffs leave 7.
- Inserting any existing refill-token variant adds 10, consumes the token, and
  updates every open vendor interface.
- An exhausted vendor creates nothing; refilling allows creation to resume.
- Item returns do not restore charges or create per-product stock.
- Access restrictions, hidden recipes, power checks, and vending delays remain
  effective, including machines without a vending animation.
- Computer and antagonist vendors display and deduct their creation costs.
- Cargo approvals and shipments work without a balance, and PDA/ID interfaces
  contain no banking controls.