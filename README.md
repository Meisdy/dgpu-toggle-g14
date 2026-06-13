# dgpu-toggle-g14

A small script to switch the discrete GPU on and off on an ASUS ROG Zephyrus
G14 (2021, GA401QE) under Linux, without `supergfxctl`.

- `dgpu on` — enable the dGPU (Hybrid). Live, no reboot.
- `dgpu off` — disable the dGPU (Integrated). Reboots.
- `dgpu status` — show the current state.

## Confirmed hardware

Tested and working on:

- ASUS ROG Zephyrus G14 2021 (GA401QE)
- RTX 3050 Ti Mobile + AMD Cezanne iGPU
- CachyOS, KDE Plasma (Wayland)

It has only been verified on this exact machine. The mechanism is generic to
ASUS laptops that expose `dgpu_disable`, but the details below were confirmed
on the GA401QE only. Other models may differ. Use on other hardware at your
own risk.

## Why this exists

`supergfxctl` is the usual tool for this, but it is deprecated and
unmaintained, and on a current systemd it fails its logind session check
(`manager is an invalid variant`), so the switch hangs pending and reverts on
reboot.

This script does the same hardware steps directly and reboots only when
needed, so there is no daemon and no session detection involved.

## How it works

The dGPU is added to / removed from the PCI bus through an ACPI WMI call
exposed at:

```
/sys/devices/platform/asus-nb-wmi/dgpu_disable    # 0 = on, 1 = off
```

Two findings on the GA401QE shaped the script:

1. **Disabling is refused while the nvidia driver is bound.** The off path
   stops `nvidia-powerd` and unloads the nvidia modules first, then writes the
   flag, then reboots. The reboot avoids a live-teardown hang.

2. **`asusctl armoury set dgpu_disable` does not work on this machine.** It
   prints `Multiple asusd interfaces devices found` and the value never
   changes. Writing the sysfs flag directly does work, so the script uses
   sysfs, not `asusctl`.

3. **Enabling is live but needs a PCI rescan.** Writing `0` alone leaves the
   slot ejected; a bus rescan (`/sys/bus/pci/rescan`) powers the card back up.
   With the rescan the enable settles without a reboot.

Because the flag reads back `1` even after the card is re-added, the script
uses `lspci` (card present on the bus) as the source of truth for `status`,
not the flag value.

## Install

```sh
git clone https://github.com/Meisdy/dgpu-toggle-g14.git
cd dgpu-toggle-g14
./install.sh
```

Or manually:

```sh
sudo install -m 755 dgpu /usr/local/bin/dgpu
```

## Usage

```sh
dgpu status          # no root needed
sudo dgpu off        # disable dGPU, prompts, then reboots
sudo dgpu on         # enable dGPU, live, no reboot
sudo dgpu off -y     # skip the reboot confirmation
```

`off` and `on` need root (they stop a service, (un)load modules, and write
sysfs). `status` does not.

## Notes

- If you also have `supergfxd` installed, disable it so it does not fight the
  flag at boot: `sudo systemctl disable --now supergfxd`.
- `off` reboots because disabling an in-use dGPU live can hang; rebooting tears
  everything down cleanly. `on` does not reboot because the card can be brought
  up live with a bus rescan.

## License

MIT. See [LICENSE](LICENSE).
