# Changelog

All notable changes to **msk_fuel** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0-beta.1] - 2026-08-29

**Pre-release.** This is the fuel business in full, but it has not been through a
season of live play yet. The mechanics work; the numbers behind them (prices,
wear rates, delivery pay) are first drafts and are meant to be tuned on your own
server. Run it on a test server before it touches a live one.

Fuel stations stop being blip coordinates and become businesses: they can be
bought, staffed, priced, supplied and worn out. Everything a player does with
one is checked against where they are actually standing, and the money and the
fuel are only ever moved by the server.

### Requires

* New dependency **`oxmysql`**. Nine tables are created and seeded automatically
  on first start, no SQL file to import.
* Add this line to your `server.cfg` if it is not there already, so group
  permissions work (it covers every MSK script at once):
  `add_ace resource.msk_core command.add_ace allow`

### Added

**Stations as entities**
* All 30 map stations became named entities with a zone (center plus radius),
  their own stock and, once bought, an owner. The server resolves the station
  from the pump position, so no pump had to be re-mapped and this works on any
  map. Seed definitions live in `config.stations.lua`.
* Blips are built from the station list and carry the station name, so renaming
  a station shows on the map right away.

**Economy**
* Stock per station per fuel type. An empty tank blocks that fuel type: the pump
  option greys out and the server refuses the sale.
* Price per liter per station, either dynamic (rising as the tank empties and as
  demand goes up) or a fixed price, always clamped to the admin limits.
* Market tick: the server-wide base price moves with total demand across all
  stations and eases back toward its anchor in quiet hours, which is what makes
  one busy station felt across the whole map.
* Company account per station plus a full transaction log.

**Ownership**
* Buying a station at the pump, and selling it back for a configurable share of
  the purchase price plus whatever is on the company account.
* Owner dashboard with eight tabs: overview, finance, prices, stock, supply,
  pumps, staff and ranks.

**Staff**
* Ranks per station with salary, delivery bonus and seven permissions. A freshly
  bought station starts with a manager and an employee rank.
* Employees hired from the list of online players. An employee with at least one
  permission gets their own dashboard, showing only what their rank allows.
* Salaries paid out of the company account every `Config.Payroll.intervalMinutes`
  to everyone online. A station that cannot cover its payroll skips it and tells
  the owner, instead of going into debt.

**Supply**
* NPC driver, unlocked once per station, for instant restocking at a surcharge,
  plus optional automatic restocking.
* Delivery runs with three rigs (van 500 L, truck 1500 L, tanker 3000 L with a
  trailer and a bulk discount): pick up the rig, drive to a depot, load, come
  back. Crash damage spills up to 30 percent of the cargo.
* Public delivery jobs at unowned stations, taken at the pump and paid per
  delivered liter out of the system. Enabled per station by the admin.

**Maintenance**
* Pumps wear out with use. A worn pump fuels slower, a broken one refuses to
  serve until it is repaired out of the company account. Pumps are never mapped:
  a pump enters the register the first time somebody fuels at it.
* Mechanic on staff, unlocked once, repairs worn pumps automatically.

**Administration**
* In-game admin dashboard (`/fueladmin`, React + Vite + Tailwind, built into
  `html/`): station CRUD, stock and prices, market parameters, unowned-station
  settings, general settings with live theming, and a group permission matrix
  with nine rights.

### Changed

* `msk_fuel:payFuelPrice` carries the fuel type and the pump coordinates now.
  The server determines the station from them, charges the station price, takes
  the liters out of its tank and books the revenue. A tank that runs dry
  mid-refuel sells what is left instead of the full amount.
* Buying and refilling a petrolcan takes petrol out of the station tank as well.
  Before, a can was an unlimited source of fuel that cost the station nothing.
* The station zone radius replaces the global `Config.FuelStationZoneDistance`,
  and `Config.Refill.price` is now only a fallback for pumps that belong to no
  station.
* The four fuel target options are built in a loop instead of being written out
  by hand eight times.
* Server files are listed explicitly in `fxmanifest.lua` instead of being
  globbed, because the admin boot file has to load last.

### Fixed

* The custom fuel pumps from `Config.CustomFuelStations` only spawned when blips
  were enabled, which had nothing to do with each other.
* The version checker crashed on any version carrying a pre-release tag: it
  split on `.` and ran `tonumber` over the pieces, so `1.2.0-beta.1` produced a
  comparison between `nil` and a number. Versions are now compared by SemVer
  rules, with a pre-release sorting before its own release.
* Settings introduced by a later version never reached a server that was already
  seeded, so a new setting silently stayed on its config default.

### Security

* Every owner and admin action is checked against the station the player is
  actually STANDING at, resolved from the pump coordinates. A station id in a
  payload proves nothing.
* The delivery flow is checked at every step, and the reported crash leak is
  clamped: the worst a manipulated client can do is deliver LESS than it paid
  for.
* Handing out rank permissions and selling a station are owner-only, whatever a
  rank says, so a manager cannot promote themselves or sell the business out
  from under its owner.
* Deposits take the money from the player before booking it, withdrawals book
  before paying out. Neither direction can create money if the other half fails.

### Changed files

* `fxmanifest.lua`, `config.lua`, `translation.lua`, `.gitignore`,
  `.github/workflows/release.yml`
* `config.business.lua`, `config.stations.lua` (new)
* `shared/perms.lua` (new)
* `server/main.lua`, `server/functions.lua`, `server/versionchecker.lua`
* `server/business/` (new): `stations.lua`, `pricing.lua`, `stock.lua`,
  `account.lua`, `employees.lua`, `ownership.lua`, `payroll.lua`, `supply.lua`,
  `delivery.lua`, `maintenance.lua`, `owner_api.lua`
* `server/admin/` (new): `store.lua`, `permissions.lua`, `seed.lua`, `api.lua`,
  `command.lua`, `boot.lua`
* `client/main.lua`, `client/target.lua`, `client/fuel.lua`
* `client/business/` (new): `sync.lua`, `dashboard.lua`, `delivery.lua`
* `client/admin/` (new): `main.lua`, `nui.lua`
* `web/**` (new NUI source), `html/**` (new build output)

## [1.1.1] - 2026-07-19

### Security
* Server-authoritative fuel: a StateBag change handler now tracks the authorized fuel value per vehicle and rolls back any illegitimate increase, so a client can no longer set arbitrary fuel levels.
* `GetVehicleFuel` now falls back to `0.0` instead of `50.0`, so a missing fuel state can no longer grant free fuel.
* Added serverside rate limiting (500 ms) on the `refillCan`, `payFuelPrice` and `updateFuelCan` events.
* Petrolcan buy and refill now verify serverside that the player is actually standing at a known fuel station, which blocks spoofed coordinates and remote triggering.

### Added
* Per vehicle type fueling distance via `Config.MaxFuelingDistance` (`default`, `heli`, `plane`) plus a serverside `GetMaxFuelingDistance` helper.
* Serverside `IsPlayerNearFuelStation` check with new `Config.MaxStationDistance` and `Config.FuelStationZoneDistance` options.
* Translation fallback: a missing key now falls back to English and then to the raw key instead of throwing an error.

### Changed
* `Config.Debug` now defaults to `false`.
* `Config.MaxFuelingDistance` changed from a single number (`100.0`) to a per vehicle type table.
* The `refillCan` event now sends the pump coordinates from the client so the server can verify the station.
* Money handling in the petrolcan and refuel events is now unified on `PayPrice`.
* Relicensed the resource to LGPL-3.0-or-later.

### Fixed
* Adjusted the wrong fuel engine failure threshold (now triggers below `500` engine health).
* Clean up the authorized fuel and rate limit tables on `entityRemoved` and `playerDropped`.

### Changed files
* `client/fuel.lua`
* `client/functions.lua`
* `client/main.lua`
* `config.lua`
* `server/functions.lua`
* `server/main.lua`
* `server/versionchecker.lua`
* `translation.lua`
* `fxmanifest.lua`
* `LICENSE`, `GPL-3.0.txt`, `.gitignore`

## [1.1.0] - 2026-06-04

### Added
* Distance watchdog that cancels an active refuel when the player, the vehicle or the pump move too far apart.

### Fixed
* Hardened the refueling flow against exploits by validating fuel amounts and distances on the server.
* Fixed several fuel consumption bugs so fuel is only drained while the engine is running.
* Fixed security issues around the fuel events to prevent tampering with fuel levels.

### Changed files
* `client/fuel.lua`
* `client/functions.lua`
* `client/main.lua`
* `server/functions.lua`
* `server/main.lua`
* `server/versionchecker.lua`

## [1.0.0] - 2024-10-19

### Added
* Initial release of the advanced fuel system for FiveM vehicles.
* Four fuel types (gas, diesel, kerosin, electric) with per-model mapping.
* Realistic refueling with a physical nozzle and rope.
* Petrolcan (jerry can) to buy, refill and refuel vehicles anywhere.
* Wrong fuel handling with progressive engine damage.
* Fuel consumption tied to engine state, with tank damage leaking.
* Default map fuel pumps, custom fuel stations and vehicle based mobile stations.
* Multi language support (German and English), ox_inventory money integration and a built-in version checker.

[1.1.1]: https://github.com/MSK-Scripts/msk_fuel/releases/tag/v1.1.1
[1.1.0]: https://github.com/MSK-Scripts/msk_fuel/releases/tag/v1.1.0
[1.0.0]: https://github.com/MSK-Scripts/msk_fuel/releases/tag/v1.0.0
