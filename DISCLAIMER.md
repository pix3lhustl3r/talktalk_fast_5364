# Disclaimer

This repository contains firmware files, notes, and helper tooling for experimenting with the Sagemcom F@ST 5364 router.

## Read this first

- Flashing firmware can brick your router.
- Changing SSH, bridge mode, DHCP, WAN, or TR-069 settings can break internet access, ISP provisioning, or remote management.
- Use this on hardware you own and control, and only on networks where you have permission to make changes.
- Keep backups of any settings you care about before making changes.
- Double-check model numbers and firmware filenames before flashing.
- If you are using this behind a family or shared internet connection, isolate it as a secondary lab router and avoid changing the primary router.

## No warranty

Everything here is provided **as-is**, with no warranty or guarantee of safety, compatibility, or fitness for any purpose.

You are solely responsible for:

- any device damage,
- loss of connectivity,
- lost configuration,
- ISP support issues,
- or any other consequences.

## Published workflow references

The downgrade-to-2600t, browser-console SSH enable, and optional re-upgrade-to-2816t workflow is described in the upstream repo and related writeups.

Before acting, verify the steps against your exact device, firmware, and risk tolerance.
