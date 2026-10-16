#!/usr/bin/env bash
# Overlay this fork's Python core on a mounted, clean upstream Pi Zero W image.
# The source image comes from the pinned official 2.9.5.6 32-bit release.
set -euo pipefail

ROOTFS="${1:?Usage: overlay-zero-w.sh ROOTFS REPO_DIR COMMIT}"
REPO_DIR="${2:?Usage: overlay-zero-w.sh ROOTFS REPO_DIR COMMIT}"
COMMIT="${3:?Usage: overlay-zero-w.sh ROOTFS REPO_DIR COMMIT}"

ROOTFS="$(realpath "$ROOTFS")"
REPO_DIR="$(realpath "$REPO_DIR")"
[ "$ROOTFS" != "/" ] || { echo "Refusing to modify /" >&2; exit 1; }
[ -d "$ROOTFS/etc" ] || { echo "Not a mounted Linux root filesystem: $ROOTFS" >&2; exit 1; }
[ -f "$REPO_DIR/pwnagotchi/__init__.py" ] || { echo "Missing fork source" >&2; exit 1; }
[ -f "$REPO_DIR/pwnagotchi/plugins/catalog.py" ] || { echo "Missing new plugin catalog" >&2; exit 1; }
[ -f "$REPO_DIR/pwnagotchi/plugins/actions.py" ] || { echo "Missing new plugin actions" >&2; exit 1; }

VENV_LIB="$ROOTFS/opt/.pwn/lib"
[ -d "$VENV_LIB" ] || { echo "Source image has no /opt/.pwn Python environment" >&2; exit 1; }

mapfile -t MATCHES < <(find "$VENV_LIB" -mindepth 3 -maxdepth 3 -type d -path '*/site-packages/pwnagotchi' -print)
[ "${#MATCHES[@]}" -eq 1 ] || {
  printf 'Expected exactly one installed Pwnagotchi Python package; found %s\n' "${#MATCHES[@]}" >&2
  exit 1
}

TARGET="${MATCHES[0]}"
SITE_PACKAGES="$(dirname "$TARGET")"
echo "Overlay target: ${TARGET#$ROOTFS}"

# Keep a copy in the image: the test device can be rolled back without the
# old core being mixed with new modules in site-packages.
tar -czf "$ROOTFS/opt/pwnagotchi-upstream-2.9.5.6-backup.tar.gz" \
  -C "$SITE_PACKAGES" pwnagotchi

# All native deps, Bettercap, PwnGrid and Nexmon stay those of the clean 32-bit
# upstream image. Only the pure-Python package, static Web UI and plugin code
# are replaced. An ARMv6 smoke test is *not* proof of runtime compatibility.
rsync -a --delete "$REPO_DIR/pwnagotchi/" "$TARGET/"

[ -f "$TARGET/ui/web/templates/plugins.html" ]
grep -q "update_version" "$TARGET/ui/web/templates/plugins.html"
grep -q "PluginCatalog" "$TARGET/ui/web/handler.py"

install -d -m 0755 "$ROOTFS/etc/pwnagotchi"
cat > "$ROOTFS/etc/pwnagotchi/image-build.txt" <<EOF
image_flavor=nicco-male-zero-w-experimental
base_image=jayofelony/pwnagotchi v2.9.5.6 32bit
base_sha256=71b4f22ea0aa72ad381c3af57747d8dc551f829dd8e1c32da1a3c078adc3c81a
source=https://github.com/Nicco-Male/pwnagotchi
source_commit=$COMMIT
installation=python-source-overlay; native packages unchanged
test_status=not_hardware_validated
EOF

# Prevent an upstream system auto-update timer from replacing the experimental
# fork before the user can test it. Does not change the Berry's live microSD.
if command -v systemctl >/dev/null 2>&1; then
  systemctl --root="$ROOTFS" disable auto-update.timer 2>/dev/null || true
fi

echo "Source overlay complete. ARMv6 runtime/hardware validation still required."
