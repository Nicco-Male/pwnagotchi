# Berry Zero W — experimental test microSD image

This is a **disposable test image**, not an update for the Berry running in
production. It is intended for a **second Raspberry Pi Zero W and a separate
microSD**.

## What is inside?

- Base: the already-published [jayofelony Pwnagotchi v2.9.5.6 **32-bit**
  image](https://github.com/jayofelony/pwnagotchi/releases/tag/v2.9.5.6).
- The Python source tree and modern plugin Web UI from the selected commit
  of this fork, overlaid into the base image's existing
  `/opt/.pwn/lib/python*/site-packages/pwnagotchi`.
- Bettercap, PwnGrid, Nexmon, prebuilt native dependencies and the operating
  system **remain unchanged** from the 2.9.5.6 base image.
- An archive of the original Python package under
  `/opt/pwnagotchi-upstream-2.9.5.6-backup.tar.gz`.
- Build metadata under `/etc/pwnagotchi/image-build.txt`.

**Not yet guaranteed:** compatibility of the newer Python core with all
native dependencies/services already present in the older base image. The
image must be boot-tested before it can be called supported. It is not a new
full ARMv6 build of Bettercap or PwnGrid.

## Build in GitHub Actions

1. Open **Actions → Berry Zero W experimental image** on the build branch,
   or open its automatic run after updating this branch.
2. Wait for the two steps: source overlay and `xz` verification.
3. Download the artifact named `berry-zero-w-test-image`, containing the
   experimental `.img.xz` file and matching SHA256 checksum.
4. Unzip the artifact and write `.img.xz` with Raspberry Pi Imager using
   **Use custom**. Use a **new microSD**.
5. Boot it on a **spare Raspberry Pi Zero W**, with normal headless access
   appropriate to the upstream image. Do not assume that existing Berry
   identity, Wi-Fi passwords, or pairing keys are included: this starts
   from a clean upstream release image.

GitHub-hosted runners need enough free disk to download the 1.3 GiB pinned
base archive and expand/recompress the disk image. CI may fail because of
runner disk capacity or release asset availability; check the job log.
Artifacts are test builds, retained for 5 days.

## Checks on the test device

    cat /etc/pwnagotchi/image-build.txt
    uname -m
    /opt/.pwn/bin/python -V
    systemctl is-active pwnagotchi bettercap pwngrid-peer
    journalctl -u pwnagotchi -b -n 80 --no-pager

Open the Web UI's **Plugins** screen. Check whether it displays the modern
installed/available counts and only offers **Update** for actual version
differences. Keep active wireless features disabled for an initial passive
test and use only networks you are authorized to assess.

## Important

- The original Berry's SD card is **never read or modified** by this build.
- No personal configuration, private keys or captured data are included.
- It is an **experimental image**; there is no official hardware validation.
- The release base is 2.9.5.6, while the working Berry reported 2.9.5.8.
  That is intentional for the first isolated trial, not a downgrade to apply
  to the working device.
- The original upstream pip `dist-info` metadata may retain version 2.9.5.6,
  while the overlaid application source comes from this fork. Use
  `image-build.txt` to identify the source revision accurately.
