# Changelog

All notable changes to **msk_fuel** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
