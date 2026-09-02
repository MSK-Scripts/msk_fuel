# Security Policy

## Supported Versions

Security fixes are applied to the latest released version of MSK Fuel. Please
make sure you are running the most recent [release](https://github.com/MSK-Scripts/msk_fuel/releases)
before reporting an issue.

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Older versions | No |

## Reporting a Vulnerability

Please do not report security vulnerabilities through public GitHub issues,
pull requests, or the Discord public channels. Exploits in a FiveM resource can
be abused on live servers as soon as they are public.

Instead, report them privately using one of these channels:

* **Email:** moritz.kohm@gmail.com
* **Discord:** send a direct message to the maintainer on the
  [MSK Scripts Discord](https://discord.gg/5hHSBRHvJE)

When reporting, please include as much of the following as you can:

* A description of the vulnerability and its impact
* Steps to reproduce, or a proof of concept
* The affected version of msk_fuel
* The event, export or command involved, if you know it
* Your setup: msk_core version, framework, inventory, and other resources that
  interact with msk_fuel

Things we are especially interested in: unvalidated client events that let a
player set their own fuel level, money or station stock, missing permission
checks in the business or admin dashboard, and anything that lets a player act
on a station they do not own or work at.

## What to Expect

* We will acknowledge your report as soon as possible.
* We will investigate and keep you updated on the progress.
* Once a fix is ready, we will release it and credit you if you wish.

Please give us a reasonable amount of time to address the issue before any
public disclosure. Thank you for helping keep MSK Fuel and its users safe.
