#!/usr/bin/env bash
# Phase C build validation, run from ~/Projects/nyxos on the host. Builds in the dev VM
# (scripts/dev-vm), exactly the pinned revisions; logs go to evidence/logs.
#
#   1. nyxos: nix flake check (incus-dev system, installed example system, catalog,
#      nyx-cli, every pinned tool)
#   2. nyx-packages: nix flake check (every package with its tests, and the
#      nyx-core / nyx-design test suites)
#   3. the live USB: nix build .#iso, copied to the host for scripts/install-vm
set -uo pipefail
cd "$(dirname "$0")/../../../../.."
logs=docs/audit/release-readiness/evidence/logs
vm() { incus exec nyxos-dev --env PATH=/run/wrappers/bin:/run/current-system/sw/bin -- "$@"; }
stamp() { date -Is; }

echo "$(stamp) nyxos flake check" | tee "$logs/build-summary.txt"
start=$(date +%s)
# As CI checks it: the repository's own (empty) overrides layer, not the VM's.
scripts/dev-vm sync && vm nix flake check -L --keep-going path:/etc/nyxos/flake >"$logs/nyxos-flake-check.log" 2>&1
echo "$(stamp) nyxos flake check exit=$? seconds=$(($(date +%s) - start))" | tee -a "$logs/build-summary.txt"

start=$(date +%s)
scripts/dev-vm packages flake check -L --keep-going >"$logs/nyx-packages-flake-check.log" 2>&1
echo "$(stamp) nyx-packages flake check exit=$? seconds=$(($(date +%s) - start))" | tee -a "$logs/build-summary.txt"

start=$(date +%s)
vm nix build -L --keep-going --out-link /root/audit-iso "path:/etc/nyxos/flake#iso" >"$logs/iso-build.log" 2>&1
rc=$?
echo "$(stamp) iso build exit=$rc seconds=$(($(date +%s) - start))" | tee -a "$logs/build-summary.txt"
if [ $rc -eq 0 ]; then
  # The ISO derivation's output is the image file itself.
  iso=$(vm readlink -f /root/audit-iso)
  vm sha256sum "$iso" | tee -a "$logs/build-summary.txt"
  vm du -h "$iso" | tee -a "$logs/build-summary.txt"
  mkdir -p ~/.cache/nyxos-test-tmp/iso
  rm -f ~/.cache/nyxos-test-tmp/iso/nyxos-*-installer.iso
  incus file pull "nyxos-dev$iso" ~/.cache/nyxos-test-tmp/iso/ && echo "$(stamp) iso copied to host" | tee -a "$logs/build-summary.txt"
fi
echo "$(stamp) done" | tee -a "$logs/build-summary.txt"
