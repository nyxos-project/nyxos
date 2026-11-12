# Dependencies and maintenance (handoff 10 §28)

Static review, 2026-11-12, of nyx-packages `d69e87e`, nyxos `97f1573` and the app
`Cargo.lock` files at their pinned `main`. Lock data was read from `flake.lock`; nothing was
built. The shared-crate drift between apps is finding NYX-PKG-002 in
[packaging-ci.md](packaging-ci.md).

## Pins at a glance

| Input / package | Source and version | How it moves | Why it exists |
| --- | --- | --- | --- |
| nixpkgs | `nixos-26.05` at `ac588ef` (2026-11-08); nyx-packages follows nyxos, same revision in both locks | manual `flake update` | base |
| Second nixpkgs | `nixos-unstable` `c0a89c3` (2026-05-27), Herdr's own (`nyxos/flake.nix:12-13`, deliberately not followed) | with Herdr tag | Herdr pins its toolchain |
| rust-overlay | `89750a2` (2026-11-10); Rust **1.99.1** minimal (`nyx-packages/lib/default.nix:21`); nixpkgs 26.05 has 1.95 | manual | apps' `build-environment.json` say 1.99.1 |
| Hyprland | Hyprland's own flake at `v0.57.2` plus `nyx-hyprland` series (13 patches), wayland-protocols 1.49 override (`pkgs/hyprland.nix:32-39`) | manual | patches; nixpkgs Hyprland too old (see the HYPR report) |
| Quickshell | nixpkgs 26.05 `quickshell` (`pkgs/nyx-shell.nix:9,23`), not pinned separately | moves with nixpkgs | shell UI runtime |
| llama.cpp | PrismML fork `PrismML-Eng/llama.cpp` at `d7b2896` (tag `prism-b12128-d7b2896`), built from source with Vulkan (`pkgs/llama-prism.nix:17-28`); CUDA build is Prism's prebuilt tarball (`pkgs/llama-prism-cuda.nix`) | manual edit of rev + hash; tag must match nyx-ai `docs/PRISM.md` | Bonsai ternary types |
| fluxd | `bjarneo/flux` tag `v0.19.1` + `flux-nyxos.patch` (3 files), 18 commits behind upstream `master` | manual, held for the Android app check | Nyx Connect backend |
| irlume / gaze | `archledger/irlume` v0.15.0 (2026-09-29), `GunduLabs/gaze` v0.5.1 | manual tag bump | face sign-in |
| libical_4 | 4.0.7 override (`pkgs/libical_4.nix`) | "drop once nixpkgs ships" | nyx-pim needs libical 4 API; nixpkgs has 3.0 |
| libshumate_1_7 | 1.7.0 (`pkgs/libshumate_1_7.nix`) | same | Maps bindings need 1.7; nixpkgs 1.6 |
| tdlib_1_8_67 | commit `bc9c263` (no tag), source build at 1 core (`pkgs/tdlib_1_8_67.nix`) | same | Pulse's typed objects; nixpkgs 1.8.63 |
| sherpa-onnx_1_13_8 | v1.13.8 plus 9 FetchContent tarballs hand-listed (`pkgs/sherpa-onnx_1_13_8.nix:14-51`) | same | Voice/Assistant bindings; nixpkgs 1.12.38 |
| pacman_7_1 | 7.1.0 (`pkgs/pacman_7_1.nix`) | same | Store's `alpm` crate links libalpm 16 even on NyxOS |
| zig_0_17 | upstream prebuilt 0.17.0 (`pkgs/zig_0_17.nix`) | manual | libghostty-vt 1.0 for Nyx Agents |
| ntgcalls | upstream prebuilt 3.0.5 `.so` (`pkgs/ntgcalls.nix`) | manual | Pulse calls |
| go | `go_1_27` for flux (`pkgs/flux.nix:21`) | nixpkgs | flux's go.mod |
| Cargo Git deps outside Nyx | `archledger/pam_sm_rust`, `archledger/rust-tss-esapi` forks (`lib/git-hashes.json`) | per app `Cargo.lock` | Biometrics PAM module and TPM |

## Unmaintained or deprecated crates

Scanned the 57 root `Cargo.lock` files of the Nyx repositories (nyx-assistant's lock is under `apps/assistant` and was not included) against RustSec "unmaintained" advisories known to
the auditor. This isn't a `cargo audit` run; confirm with `cargo audit`.

| Crate | Advisory | Repos |
| --- | --- | --- |
| `bincode` 1.3.3 | RUSTSEC-2025-0141 (unmaintained) | nyx-chat, nyx-glimpse |
| `fxhash` 0.2.1 | RUSTSEC-2025-0057 | nyx-chat, nyx-news |
| `paste` 1.0.15 | RUSTSEC-2024-0436 | nyx-capture, nyx-music, nyx-system |
| `number_prefix` 0.4.0 | RUSTSEC-2025-0119 | nyx-voice |
| `rustls-pemfile` 2.2.0 | RUSTSEC-2025-0134 | nyx-containers |
| `serde_yaml` 0.9.34+deprecated | deprecated by its author | nyx-containers |

None of these is GTK3-era or known-vulnerable. GTK is uniform: gtk4 0.11.5 (49 locks) with
the `v4_18` feature (54 manifests; one `v4_12`), glib 0.22.10.

## Duplication

- Across apps: rand 0.8/0.9/0.10 (14/5/21 locks), thiserror 1/2, syn 2/3, zbus 5.19 (39)
  and 6.2 (1), reqwest 0.12 (21) and 0.13 (1), rusqlite 0.37 (2) and 0.40 (30), tokio in
  four patch versions.
- Within one lock: up to 30 crate names at more than one version (nyx-news), 26 in
  nyx-core and nyx-voice.
- Every app compiles its own copy of nyx-core and nyx-design (NYX-PKG-002). Two nixpkgs
  and two rust-overlay nodes are in nyxos's lock (Herdr's).

## Automated updates

- Dependabot only for GitHub Actions in nyxos and nyx-packages (`.github/dependabot.yml`).
  No Dependabot or Renovate for Cargo, flake inputs, or app repositories.
- nyxos `tool-updates.yml` covers the 11 third-party CLI and desktop tools in
  `pkgs/tools/sources.json` (sound design: vendor-hash check, sandboxed build, PRs only).
- No `cargo audit` or `cargo deny` in any workflow. `deny.toml` exists in nyx-files and
  `nyx-passwords/crates/nyx-passwords-core`, but no CI job runs it.

---

## Findings

### NYX-DEP-001: No automated dependency monitoring for Rust crates or flake inputs

- **Component:** all app repos; nyx-packages `flake.lock`; `.github/dependabot.yml` (nyxos, nyx-packages)
- **Category:** CI
- **Severity:** P2
- **Status of feature:** approved, not implemented
- **Description:** Nothing proposes updates or flags advisories for about 58 Cargo lockfiles (up to 501 crates each), the nixpkgs, rust-overlay, Hyprland, irlume and gaze inputs, or the nine custom-version packages. Dependabot is configured only for GitHub Actions. `deny.toml` files exist but aren't run in CI.
- **Expected:** §28 "Missing automated updates"; §26 "Security checks", "Dependency monitoring".
- **Actual:** `find ~/Projects -maxdepth 3 -name dependabot.yml` finds only nyxos and nyx-packages, both `package-ecosystem: github-actions`. `rg 'cargo (audit|deny)' */.github` finds nothing.
- **Reproduce / verify:** as above
- **Evidence:** `nyxos/.github/dependabot.yml:1-7`
- **Affected versions:** all
- **User impact:** A RustSec vulnerability in a crate shipped in the desktop (for example in an HTTP, TLS or parser crate) goes unnoticed until someone looks.
- **Recommended correction:** A scheduled nyx-packages workflow that runs `cargo audit` (or `cargo deny check advisories`) over every pinned source's `Cargo.lock` and opens issues. Renovate or Dependabot for Cargo in the shared crates. A weekly `flake update` PR for nixpkgs and rust-overlay, gated by CI.
- **Effort:** M
- **Dependencies:** NYX-CI-001, NYX-PKG-002
- **Verification criteria:** A scheduled job reports advisories for all pinned sources. Flake input PRs appear automatically.

### NYX-DEP-002: Six unmaintained or deprecated crates in shipped apps

- **Component:** `Cargo.lock` of nyx-chat, nyx-glimpse, nyx-news, nyx-capture, nyx-music, nyx-system, nyx-voice, nyx-containers
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** See the table above: bincode 1, fxhash, paste, number_prefix, rustls-pemfile, serde_yaml.
- **Expected:** §28 "Unmaintained libraries".
- **Actual:** as listed, from each repository's `Cargo.lock`.
- **Reproduce / verify:** `cargo audit` in each repository, or `grep -l 'name = "bincode"' */Cargo.lock`
- **Evidence:** as above
- **Affected versions:** current pins
- **User impact:** No direct impact today; future fixes won't come upstream.
- **Recommended correction:** Replace them: bincode with `bincode` 2 or postcard, fxhash with rustc-hash, serde_yaml with `serde_yml` or `yaml-rust2`, rustls-pemfile with `rustls-pki-types` PEM APIs. `paste` and `number_prefix` are transitive; bump their parents.
- **Effort:** S
- **Dependencies:** NYX-DEP-001
- **Verification criteria:** `cargo audit` shows no unmaintained warnings for these.

### NYX-DEP-003: Nine packages pinned ahead of nixpkgs, each maintained by hand

- **Component:** nyx-packages `pkgs/libical_4.nix`, `libshumate_1_7.nix`, `tdlib_1_8_67.nix`, `sherpa-onnx_1_13_8.nix`, `pacman_7_1.nix`, `zig_0_17.nix`, `hyprland.nix:32-39` (wayland-protocols 1.49), `lib/default.nix:21` (Rust 1.99.1), `pkgs/flux.nix:21` (go_1_27)
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Apps follow Arch's library versions, so NyxOS carries newer libraries than its nixpkgs release. Each override says "drop once nixpkgs ships …" but nothing tracks when. These overrides no longer get nixpkgs' security patches: libical, tdlib (network-facing Telegram client), pacman and sherpa-onnx's nine vendored archives are now NyxOS's responsibility. tdlib also has no upstream tag (commit `bc9c263`). The whole Rust stack depends on a third-party overlay for a toolchain four releases newer than nixpkgs. Not built separately: nixpkgs' own libical 3 and libshumate 1.6 stay in the closure for other packages.
- **Expected:** §28 "Outdated dependencies", "Upstream compatibility risks", "Evaluate maintenance cost".
- **Actual:** files above. The pins date from 2026-11-03 to 11-10.
- **Reproduce / verify:** read the files; compare with `nix eval nixpkgs#libical.version` etc. at the pinned nixpkgs.
- **Evidence:** as above
- **Affected versions:** nyx-packages `d69e87e`
- **User impact:** Security fixes for these libraries reach NyxOS only when someone edits the override. Each nixpkgs bump may break an override build.
- **Recommended correction:** Keep a table in `docs/compatibility.md` with each override, its reason, upstream nixpkgs status and a review date. Add a CI check that fails once nixpkgs' version is at least the override's (so it gets dropped). Prefer building apps against nixpkgs' versions where the API gap is small (libshumate, pacman: build Store without alpm on NyxOS).
- **Effort:** M
- **Dependencies:** NYX-DEP-001
- **Verification criteria:** Every override has an owner and review date, and a check reports overrides that nixpkgs has caught up with.

### NYX-DEP-004: Forks and patch series with manual, single-person upkeep

- **Component:** nyx-packages `pkgs/llama-prism.nix`, `pkgs/llama-prism-cuda.nix`, `pkgs/flux.nix` + `flux-nyxos.patch`, `pkgs/hyprland.nix` + nyx-hyprland `patches/0.57.2` (13 patches); nyxos `patches/nixpkgs/0001-…`, `0002-…`; Cargo Git forks `archledger/pam_sm_rust`, `archledger/rust-tss-esapi`
- **Category:** architecture
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:**
  - llama.cpp comes from PrismML's fork at one commit (b12128). The CUDA variant is a prebuilt release. There's no feed or update job, so upstream llama.cpp fixes (including security fixes to the server, which AI Core exposes on 127.0.0.1:8080 according to the nyx-packages README) arrive only when Prism rebases and someone edits the rev, hash and tag in two files plus nyx-ai's `docs/PRISM.md`.
  - flux is held at v0.19.1, 18 commits behind, with a patch over three files.
  - The Hyprland series (13 patches) must be rebased for each Hyprland release. It applies to Hyprland's own flake rather than nixpkgs, which also pins Hyprland's own hyprutils and aquamarine (see the HYPR report).
  - The two nixpkgs patches change NixOS source by line context (`top-level.nix`, `switch-to-configuration-ng/src/main.rs`). The second forces a local rebuild of `switch-to-configuration-ng` and can fail to apply on any nixpkgs bump.
  - PAM and TPM crates come from a personal fork owner (archledger), as do irlume and the face-auth pieces: security-critical code with a bus factor of one, outside Nyx's control.
- **Expected:** §28 "Unnecessary forks", "Fragile patches", special attention to customized Hyprland, llama.cpp, PrismML patch and fluxd.
- **Actual:** files above.
- **Reproduce / verify:** read the files; `git -C ~/Projects/flux rev-list --count v0.19.1..origin/master` gives 18.
- **Evidence:** as above
- **Affected versions:** current pins
- **User impact:** Delayed security fixes in network-exposed or authentication components. Rebases block nixpkgs and Hyprland upgrades.
- **Recommended correction:** Write down an upstreaming plan per fork: ask PrismML to upstream Bonsai types, upstream the flux NyxOS hooks as options, and send Hyprland patches upstream where accepted. Add release-feed watchers (like `tool-updates.yml`) for llama-prism, flux, Hyprland, irlume and gaze. Replace the switch-to-configuration patch with a wrapper message, or drop it. Vendor or mirror the archledger forks under the org with review.
- **Effort:** L
- **Dependencies:** HYPR findings; NYX-PKG-004
- **Verification criteria:** Each fork has a documented upstream status and an automated new-release alert.

### NYX-DEP-005: Duplicated crate versions and a second nixpkgs inflate builds and the closure

- **Component:** app `Cargo.lock` files; nyxos `flake.lock` (Herdr's nixpkgs and rust-overlay)
- **Category:** performance
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** See "Duplication" above. Each app also embeds its own build of nyx-core and nyx-design. Herdr brings a second nixpkgs (nixos-unstable, May 2026) into every system's evaluation and closure.
- **Expected:** §28 "Duplicated dependencies".
- **Actual:** counts above, from a Python scan of `Cargo.lock` files.
- **Reproduce / verify:** `cargo tree -d` in each repository; `nix flake metadata ~/Projects/nyxos`
- **Evidence:** as above
- **Affected versions:** current
- **User impact:** Longer builds and updates, a larger disk footprint, more CVE surface.
- **Recommended correction:** Align shared dependency versions through nyx-core's workspace (one zbus, one reqwest, one rand). Package Herdr against NyxOS's nixpkgs, or use its binary.
- **Effort:** M
- **Dependencies:** NYX-PKG-002
- **Verification criteria:** `cargo tree -d` shows fewer duplicates; nyxos's lock has one nixpkgs node.
