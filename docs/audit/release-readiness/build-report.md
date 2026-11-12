# Build and packaging validation (Phase C)

Run 2026-11-12 00:29 to 01:03 in the dev VM (`nyxos-dev`), at nyxos `97f1573` and
nyx-packages `d69e87e` (both the `origin/main` of the time), with
[evidence/scripts/build-validation.sh](evidence/scripts/build-validation.sh). Logs and
timings: [evidence/logs/](evidence/logs/) (`build-summary.txt`, `nyxos-flake-check.log.gz`,
`nyx-packages-flake-check.log.gz`, `iso-build.log.gz`).

## Results

| Step | Command | Result | Time | Built locally / fetched |
| --- | --- | --- | ---: | --- |
| nyxos flake check (as CI: repository overrides layer) | `nix flake check -L --keep-going path:/etc/nyxos/flake` | **pass** ("all checks passed!") | 211 s | 230 built, 91 fetched |
| nyx-packages flake check | `nix flake check -L --keep-going` in nyx-packages | **pass** | 1,434 s | 165 built, 843 fetched |
| Live USB | `nix build path:/etc/nyxos/flake#iso` | **pass**, 3.1 GiB | 354 s | 396 built, 63 fetched |

The nyxos check covers the dev-VM system (`incus-dev`), an installed machine as the
installer writes one (`installed`), the software catalog against the system
(`catalog`), `nyx-cli`, and every pinned third-party tool (`checks/tools.nix`). The
nyx-packages check covers every package (each build runs its Cargo tests, with the
exclusions listed in [packaging-ci.md](packaging-ci.md) NYX-PKG-001) and the
nyx-core and nyx-design test suites.

ISO: `nyxos-0.1.0-installer.iso`, sha256
`7b5c27e4e924b61178823f673b4aa5544052e7a4db838baa6539c82b0643c4bf`, store path
`/nix/store/1ppy3qn4g1xipzdswk819y1mjm8c0460-nyxos-0.1.0-installer.iso`. Used for the
install test in Phase D.

## Tests that ran in this build

Most package outputs came from the binary caches (their tests ran when they were first
built). The derivations rebuilt here ran their tests in this run:

| Derivation | Test binaries | Passed | Failed | Ignored |
| --- | ---: | ---: | ---: | ---: |
| nyx-core-tests | 44 | | | |
| nyx-design-tests | 16 | | | |
| nyx-desktop-widgets | 5 | | | |
| nyx-installer | 4 | | | |
| **Total** | 69 | **373** | **0** | **1** |

Rebuilt locally because the caches didn't have them: Hyprland 0.57.2 with the Nyx
series, the nyx-core and nyx-design crates at the shell's revisions (`166ff17`,
`553f655`), nyx-desktop-widgets, nyx-installer, sherpa-onnx 1.13.8. 20 NARs that
`nyxos.cachix.org` lists were missing ("file 'nar/…' does not exist in binary cache");
Nix fell back to building.

## Observations

- **Reproducibility at the pinned revisions: good.** All three builds pass from a clean
  evaluation of what's on GitHub. Every input is locked; nyx-packages follows nyxos'
  nixpkgs (`ac588ef`, 2026-11-08) when built as part of the system. Herdr brings its own
  older nixpkgs (2026-05-27) by design (dependencies.md NYX-DEP-005).
- **CI is not doing this.** GitHub Actions has failed every push to both repositories
  since 10 November at the format step, so these builds are the only validation of the
  current revisions (packaging-ci.md NYX-CI-001). The 0.1.0 tag was never built by CI.
- **Cache coverage gaps.** The standalone nyx-packages build had to compile Hyprland and
  several crates that the system closure already had, meaning the standalone and the
  system derivations differ, and some cache entries were missing. A fresh install that
  can't reach the cache builds Hyprland itself (tens of minutes); the live USB carries
  the system's closure, so an offline install is unaffected (`scripts/offline-check`).
- **Tooling defect found during the run:** `scripts/dev-vm packages` copies the VM's lock
  back over the host checkout afterwards, which can silently undo another session's
  uncommitted lock change (see evidence/runtime-notes.md, NYX-CI-007 in
  [packaging-ci.md](packaging-ci.md)).
- The build script's first version looked for the ISO in an `iso/` folder; the output is
  the image itself. Fixed in the script; the ISO was copied by hand.

## Gate A (build integrity): pass at the pinned revisions

Every required component builds reproducibly from its locked revision, but no automated
gate enforces it (CI red, no branch protection): see [gates.md](gates.md).
