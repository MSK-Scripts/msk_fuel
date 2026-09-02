# Contributing to MSK Fuel

Thanks for taking the time to contribute. MSK Fuel is a fuel system for FiveM
that turns fuel stations into businesses players can buy, staff, price and
supply. This guide explains how to report issues, suggest features, and open
pull requests.

## Ways to contribute

* **Report a bug** using the bug report issue template.
* **Request a feature** using the feature request issue template.
* **Improve the docs** at [docu.msk-scripts.de](https://docu.msk-scripts.de/docs/msk_fuel/).
* **Open a pull request** with a fix or a new feature.

If you just have a question or want to discuss an idea first, join the
[MSK Scripts Discord](https://discord.gg/5hHSBRHvJE).

## Before you start

* **Lua 5.4** is required, the resource sets `lua54 'yes'`.
* Dependencies are `msk_core`, `ox_target`, `ox_inventory` and `oxmysql`.
  Framework access always goes through the msk_core bridge, never talk to ESX
  or QBCore directly.
* The fuel state lives on **StateBags** and is network synchronized. Treat the
  server as the only authority: level, price and stock changes belong on the
  server, the client only asks for them.
* Server-side validation is mandatory for anything triggered from the client.
  Never trust client input, and never trust a client-sent amount, price or
  station id.

## Project layout

```
msk_fuel/
├── config.lua              general settings
├── config.stations.lua     station seed data
├── config.business.lua     business, pricing, supply and staff settings
├── config.vehicles.lua     vehicle model to fuel type mapping
├── config.tankvolume.lua   per-model tank volume overrides
├── translation.lua         all languages for the in-game text
├── shared/                 shared helpers and permission constants
├── client/                 state, fuel logic, target, business, admin
├── server/                 business modules, admin dashboard, commands
├── html/                   built NUI, committed, referenced by fxmanifest
└── web/                    NUI source (React + Vite + TypeScript + Tailwind)
```

The server load order in `fxmanifest.lua` is written out by hand instead of
globbed. `server/admin/boot.lua` depends on every other admin file and has to
load last, and the business modules have to exist before `server/main.lua` uses
them. New files have to be added there or they never load.

## Working on the NUI

The NUI source lives in `web/`, the build output goes to `html/` and is
committed so the server never needs npm.

```bash
cd web
npm install
npm run dev     # browser dev
npm run build   # rebuilds ../html, commit it after UI changes
```

After any UI change, run `npm run build` and commit the updated `html/`.

## Pull request checklist

1. Fork the repo and create a branch from `main`.
2. Keep your change focused. One feature or fix per pull request.
3. Match the existing code style (naming, indentation, comment density).
4. Register new client or server files in `fxmanifest.lua`, in the right spot
   of the load order.
5. Test in game, at least the path you touched.
6. If you changed the NUI, rebuild and commit `html/`.
7. Add new user facing strings to `translation.lua` for every language that is
   already there.
8. Update `CHANGELOG.md` and the documentation if behavior, config or database
   schema changed.
9. Fill out the pull request template.

## Reporting security issues

Please do not open public issues for security vulnerabilities. See
[SECURITY.md](SECURITY.md) for how to report them privately.

## License

By contributing, you agree that your contributions will be licensed under the
project's **LGPL-3.0-or-later** license. See [LICENSE](../LICENSE).
