# Raspberry Pi Zero W / ARMv6 hard-float support

Status: **experimental / not yet a supported image**.

This fork tracks jayofelony/pwnagotchi's `noai` branch while working toward
a shared Pwnagotchi core and Web UI on Raspberry Pi Zero W (ARMv6) and newer
ARM64 devices (including OrangeGotchi).

## Why ARMv6 needs its own build path

The original Raspberry Pi Zero W has an ARM1176JZF-S (ARMv6) CPU. Raspberry
Pi OS 32-bit is built for ARMv6 with VFP hard-float support. The name
`armhf` alone is **not** sufficient proof of compatibility: Debian's
standard armhf port targets a newer ARM baseline, so Debian armhf binaries
must not automatically be treated as Raspberry Pi Zero W-compatible.

We must validate the CPU instruction baseline, ABI and native extension
wheels (when present). ARM64 artifacts will remain separate.

## First milestone: source smoke checks

The workflow in `.github/workflows/arm-compat-smoke.yml` executes
`scripts/ci/arm-smoke.py` inside 32-bit ARMv6 and 64-bit ARM Python 3.13
containers under QEMU. It verifies that the Pwnagotchi Python core
compiles, that Python pointer size matches the target and that the modern
plugin UI still has the corresponding catalog backend.

**Passing this smoke check does NOT mean a deployable ARMv6 package exists.**
The ARMv6 CI image currently uses Alpine/musl, not Raspberry Pi OS/glibc.
It does not build or install native dependencies, bring up Bettercap or
PwnGrid, start systemd services, or test Wi-Fi monitor mode.

## Read-only baseline on the existing Berry Zero W

Run this on the Berry before discussing any replacement:

    uname -m
    dpkg --print-architecture
    /opt/.pwn/bin/python -V
    /opt/.pwn/bin/python -m pip show pwnagotchi
    command -v bettercap || true
    command -v pwngrid || true
    systemctl is-active pwnagotchi bettercap pwngrid-peer || true

Known baseline reported on 2026-10-16: Pwnagotchi 2.9.5.8, Python 3.13,
installed under /opt/.pwn. The existing install is **not** updated by
the smoke workflow.

Do **not** run `pip install --upgrade pwnagotchi` on the working Pi Zero
and do **not** overwrite its microSD while support is experimental.
Keep a recoverable microSD image before eventual native tests.

## Next milestones

1. Establish a reproducible Raspberry Pi OS 32-bit build environment
   (ARMv6 hard-float + glibc), and pin a Python 3.13-compatible dependency set.
2. Build and smoke-test the full Pwnagotchi wheel and any native dependencies.
3. Build and test ARMv6-compatible Bettercap and PwnGrid separately; their
   release numbers and CPU requirements are independent of Pwnagotchi.
4. Test services, Web UI, Wi-Fi monitor mode and plugin catalog on a spare
   microSD in real Pi Zero W hardware.
5. Publish versioned artifacts with rollback instructions only after validation.

Upstream code and licensing remain attributed in the repository. This
experimental work does not claim any new official upstream support.
