#!/usr/bin/env python3
"""Dependency-free architecture and source smoke test.

This deliberately does not claim that native dependencies or Wi-Fi work on a Pi.
Run on real ARMv6/ARM64 Python (or under QEMU) to catch basic regressions.
"""
import argparse
import platform
import struct
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected", choices=("armv6", "arm64"), required=True)
    args = parser.parse_args()

    bits = struct.calcsize("P") * 8
    expected_bits = {"armv6": 32, "arm64": 64}[args.expected]
    if bits != expected_bits:
        parser.error(f"{args.expected} needs {expected_bits}-bit Python, got {bits}-bit")

    machine = platform.machine().lower()
    if not (machine.startswith("arm") or machine in ("aarch64", "arm64")):
        parser.error(f"Not running on an ARM userspace: {machine}")

    pkg = ROOT / "pwnagotchi"
    sources = sorted(pkg.rglob("*.py"))
    # Bundled third-party display drivers are tested separately with hardware.
    sources = [p for p in sources if (pkg / "ui" / "hw" / "libs") not in p.parents]
    if len(sources) < 30:
        parser.error(f"Unexpectedly few Python sources ({len(sources)})")

    failures = []
    for path in sources:
        try:
            compile(path.read_bytes(), str(path.relative_to(ROOT)), "exec")
        except (SyntaxError, ValueError) as exc:
            failures.append(f"{path.relative_to(ROOT)}: {exc}")
    if failures:
        parser.error("Syntax checks failed:\n" + "\n".join(failures))

    with (ROOT / "pyproject.toml").open("rb") as file:
        project = tomllib.load(file)["project"]
    if project["name"] != "pwnagotchi":
        parser.error("pyproject.toml does not describe Pwnagotchi")

    required = (
        "pwnagotchi/plugins/catalog.py",
        "pwnagotchi/plugins/actions.py",
        "pwnagotchi/ui/web/handler.py",
        "pwnagotchi/ui/web/templates/plugins.html",
    )
    for item in required:
        if not (ROOT / item).is_file():
            parser.error(f"Missing modern plugin UI component: {item}")

    template = (ROOT / "pwnagotchi/ui/web/templates/plugins.html").read_text()
    handler = (ROOT / "pwnagotchi/ui/web/handler.py").read_text()
    if "{% if p.update_version %}" not in template or "PluginCatalog" not in handler:
        parser.error("Plugin update UI no longer matches the catalog backend")

    print(
        f"PASS: target={args.expected}, machine={machine}, Python={sys.version.split()[0]}, "
        f"userspace={bits}-bit, Python files checked={len(sources)}"
    )
    print("NOTE: no native wheels, Bettercap, PwnGrid, Wi-Fi, or hardware validated.")


if __name__ == "__main__":
    main()
