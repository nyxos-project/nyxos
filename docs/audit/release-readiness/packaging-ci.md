# Packaging and CI/CD (handoff 10 §25, §26)

Static review, 2026-11-12. Revisions: nyxos `97f1573`, nyx-packages `d69e87e` (both
`origin/main`). GitHub data from read-only `gh` calls the same night. Nothing was built.

## Summary

The packaging itself is careful: every source is pinned by `flake.lock` or a fixed hash,
Cargo Git dependencies are fetched by hash (`lib/git-hashes.json`), service files are
rewritten to store paths with a guard that fails the build if anything still points at
`/usr` or `~/.local`, desktop entries have no absolute `Exec=` and all carry `Icon=`, and
the dev VM (`hosts/incus-dev`) is a separate `nixosConfiguration` that no installed system
imports. nyxos's `nixpkgs` and nyx-packages' `nixpkgs` resolve to the same revision
(`ac588ef`, nixos-26.05), so the lock is consistent.

The release process around it is not. CI on both distribution repositories has been red
for every push since 10–11 November, always at the `nix fmt --check` step, so no package or
system has been built by CI since then. Nothing is protected: no branch protection or
rulesets on `main` or `stable`, and `stable` is moved by hand. The 0.1.0 pre-release tag
points at a commit CI never built, and `stable`, the channel installed machines follow, is
40 commits behind that tag.

### Is the inventory's CI claim accurate?

`inventory.md` says "nyx-packages' CI builds every package, which covers compilation but
not their own tests". **By design it is better than that, but at present it is worse:**

- Design: `checks = packages // ./checks` (`nyx-packages/flake.nix:319-323`) and CI builds
  every check (`.github/workflows/ci.yml:45-86`). `buildRustPackage` runs `cargo test` by
  default (`checkType = "debug"`, `lib/default.nix:187`; no `doCheck = false` anywhere in
  nyx-packages or nyxos). So package builds **do** run tests, narrowed in about ten
  packages (see NYX-PKG-001). The unfree `llama-prism-cuda` is not a package output and is
  never built by CI.
- Today: the last nyx-packages CI run that built anything was `8ecfdc7` on
  2026-11-10T18:41Z. Of the 35 runs since then, 34 failed in about 20 s at `Format` (every one sampled; one has no conclusion recorded), before
  evaluation; `stable` (`558453c`) also failed `Format` and was never built by
  nyx-packages' CI.

## Recent CI results

`gh run list -R nyxos-project/nyx-packages -L 15` and the same for nyxos. Every run below
is a push to `main`; every failure was the `Format` step (job `evaluate`), so the `build`
job never ran.

| Repo | Commit | Started (UTC) | Result | Failing step / files |
| --- | --- | --- | --- | --- |
| nyx-packages | `d69e87e` | 11-12 05:48 | failure | Format: `lib/default.nix`, `pkgs/nyx-lyra.nix` |
| nyx-packages | `5079a7b` | 11-12 05:24 | failure | Format |
| nyx-packages | `5269203` | 11-12 05:15 | failure | Format |
| nyx-packages | `279aedb` | 11-12 04:57 | failure | Format |
| nyx-packages | `baab55f` | 11-12 04:09 | failure | Format |
| nyx-packages | `7be6d58`, `68c63f3`, `8367d52`, `79d1a2a`, `27f0c47`, `ceb9284`, `bdf1b07`, `1d9e5a7`, `45830f0`, `fd95802` | 11-12 01:24–03:53 | failure ×10 | Format |
| nyxos | `97f1573` | 11-12 05:48 | failure | Format: `iso/boot-menu.nix`, `modules/nixos/desktop.nix` |
| nyxos | `d632770` (tag `v0.1.0`) | 11-12 05:24 | failure | Format |
| nyxos | 13 earlier pushes | 11-12 03:16–05:15 | failure ×13 | Format |

Longer window:

| Repo | Runs examined | Success | Failure | Cancelled | Last green build |
| --- | ---: | ---: | ---: | ---: | --- |
| nyx-packages | last 100 | 10 | 77 | 12 | `8ecfdc7`, 2026-11-10 18:41Z |
| nyxos (`main`, CI workflow) | 146 | 42 | 88 | 16 | `e7a4a92`, 2026-11-11 05:26Z |
| nyxos `stable` = `known-good/22` = `7454358` | | success (push to `stable`, 11-10 17:25Z) | | | |
| nyx-packages `stable` = `558453c` | | | failure ×2 (Format) | | never |

Sampled app repositories (`gh run list -R design-nexus/<repo> -L 5`):

| Repo | Trigger of its check | Last runs |
| --- | --- | --- |
| nyx-core | pull_request, dispatch | last run 2026-11-04 (dispatch), success after 3 failures |
| nyx-design | pull_request, dispatch | one run ever, 2026-11-04 |
| nyx-settings | pull_request, dispatch | last 5 runs all failure, last 2026-11-03 |
| nyx-assistant | pull_request, dispatch | last 4 runs all failure, last 2026-11-03 |
| nyx-files | push (build only, no tests) | success on push |
| nyx-bar, nyx-greeter | push | success on push |
| nyx-notes | push | failure on each of the last 5 pushes (to 11-11) |
| nyx-cloud | push (build only) | failure since 2026-11-02 |

Reproduce: `gh run list -R nyxos-project/nyx-packages -L 100 --json conclusion,headSha,createdAt`;
`gh run view 43163810618 -R nyxos-project/nyx-packages --log-failed | grep 'not formatted'`.

## What CI does

| Workflow | Triggers | Runs | Environment | Publishes |
| --- | --- | --- | --- | --- |
| nyxos `ci.yml` | push main/stable, pull_request, dispatch | `nix fmt --check`, eval of all checks and packages, build of `incus-dev`, `installed` (the example machine), `catalog`, `nyx-cli`, each tool check | ubuntu + Nix | Cachix push (not for `tool-update/*`) |
| nyxos `tool-updates.yml` | every 6 h, dispatch | find upstream release, verify vendor hash, build + smoke check; PR per tool | ubuntu + Nix, `propose` read-only and no secrets | PRs/issues with the run's token |
| nyx-packages `ci.yml` | push main/stable, pull_request, dispatch | `nix fmt --check`, `nix flake check --no-build`, build of every package and the nyx-core/nyx-design test checks in 6 shards | ubuntu + Nix | Cachix push |
| App `check.yml` (31 repos) | pull_request, dispatch only | `cargo check/clippy/test` or `tools/ci.py` | Arch container pinned by digest, Arch archive snapshot 2026-10-20 | nothing |
| App `release.yml` (about 40 repos) | dispatch | `tools/ci.py`, `tools/release.py --publish` | Arch container | GitHub release (Arch/Omarchy tarballs) |
| Push-triggered app checks | push | nyx-bar, nyx-greeter, nyx-desktop-widgets, nyx-notes (tests); nyx-files, nyx-cloud (build only); nyx-plugin-index | Arch / ubuntu | nothing |

What's done well: every action in nyxos and nyx-packages is pinned by SHA (Dependabot
proposes bumps); default workflow token is read-only; both use `pull_request`, never
`pull_request_target`, so fork PRs get no Cachix token (`nyx-packages/.github/workflows/ci.yml:74-79`);
`tool-update/*` builds get no token and skip the push (`nyxos/.github/workflows/ci.yml:84-88`);
`publish-tool-updates` refuses a patch that touches anything but that tool's pin
(`nyxos/scripts/publish-tool-updates:61-72`); no tool has `autoMerge` set and the repository
has `allow_auto_merge: false`, so automated updates cannot merge themselves.

Gaps not covered by a finding below: nyx-files' and nyx-cloud's `build.yml` use the
unpinned `archlinux:base-devel` image, a live `pacman -Syu` and `actions/checkout@v4`; app
CI tests the Arch build, not the NyxOS one (only nyx-packages tests that).

---

## Findings

### NYX-PKG-001: Package test runs are narrowed, and Files' security tests run nowhere

- **Component:** nyx-packages `pkgs/nyx-files.nix`, `pkgs/nyx-files-skipped-tests.txt`, `pkgs/nyx-settings.nix`, `pkgs/nyx-assistant.nix`, `pkgs/nyx-glimpse.nix`, `pkgs/nyx-agents.nix`
- **Category:** packaging
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Packages run tests, but many suites are cut down. Files skips 83 tests. Several packages run only one crate or one binary's tests. Files' own CI only builds, so the skipped tests aren't run anywhere.
- **Expected:** Handoff 10 §25/§26: "Tests run on required targets". Tests excluded from the sandbox should run somewhere, for example a VM test or the app's own CI.
- **Actual:** `nyx-files-skipped-tests.txt:1-3` says these are tests "the Files repository's own CI doesn't run (it only builds)". There are 83 names (30 `portal_setup`, 16 `adapters`, 15 `services`, 9 `sandbox_helper`, others). Security-relevant ones are among them: `sandbox::tests::staged_secrets_are_inherited_only_when_explicitly_mapped_to_stdin`, `services::file_providers::tests::discovery_refuses_symlinks_writable_registration_and_relative_programs` and `portal_setup::udiskie::tests::install_refuses_symlink_target`. `nyx-files/.github/workflows/build.yml` runs only `cargo build --release --locked`. Narrowed scopes: nyx-settings tests only `-p nyx-settings --bin nyx-settings` (`nyx-settings.nix:20-25`, against 288 tests in the repo); nyx-assistant only `assistant-core` and `assistant-policy` `--lib` (`nyx-assistant.nix:143-149`, against 230); glimpse `-p nyx-glimpse --lib --bins` plus 3 skips; agents 4 of its crates. Further skips: backup 2, maps 1, pulse 1, flux 2. The README says "82 desktop-only tests skipped" (`README.md:43`).
- **Reproduce / verify:** `grep -vc '^\(#\|$\)' pkgs/nyx-files-skipped-tests.txt`; `rg -n 'cargoTestFlags|checkFlags' pkgs/`
- **Evidence:** as above
- **Affected versions:** nyx-packages `d69e87e`, nyx-files `4a2d8bf`
- **User impact:** Regressions in the Files sandbox, file-provider and udiskie code paths reach users unnoticed.
- **Recommended correction:** Run the full Files suite in its own CI (Arch container with bubblewrap, FUSE and a session bus) or as a NixOS VM test. Widen `cargoTestFlags` to `--workspace` where only sandbox-incompatible tests need excluding, and skip those by name. Fix the README count.
- **Effort:** M
- **Dependencies:** NYX-CI-004
- **Verification criteria:** Every test in the skip list runs green in some CI job. Settings and Assistant run `--workspace` minus named skips.

### NYX-PKG-002: Shared crates drift: apps build ten nyx-core and seven nyx-design revisions

- **Component:** every app `Cargo.lock`; nyx-packages `lib/git-hashes.json`
- **Category:** architecture
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Apps pull nyx-core, nyx-design and other shared crates as Cargo Git dependencies pinned per app. The pins have spread: nyx-core at 10 revisions, nyx-design 7, nyx-ai 3, nyx-share 3, nyx-cloud 2, nyx-biometrics 2. Some single binaries mix revisions: nyx-shell's lock has nyx-core crates from 3 revisions (`4378e24`, `51d82b7`, `a93881d`), nyx-assistant's from 2 (`4f05fb8`, `394ddf8`). nyx-accounts is used at `afdc148` everywhere, behind its `main` `e0df68a`.
- **Expected:** §28 "Duplicated dependencies", §9 one theme and widget system. A fix in a shared crate should reach every app in one release.
- **Actual:** `evidence/shared-crate-pins.txt`. The shell components are on nyx-design `553f655` (8 commits behind `main`), most apps on `cf39397` (18 behind), Settings `997a2c1`, bar `0117f5f`, system `53bf2d7`. nyx-packages carries 35 Git hashes (`lib/git-hashes.json`); 9 are nyx-core and 7 nyx-design.
- **Reproduce / verify:** `grep -o 'nyx-core.git?rev=[0-9a-f]\{7\}' */Cargo.lock | sort | uniq -c`
- **Evidence:** `evidence/shared-crate-pins.txt`; `nyx-shell/Cargo.lock`; `nyx-assistant/apps/assistant/Cargo.lock`
- **Affected versions:** pins as of 2026-11-12
- **User impact:** Theme, widget, path or identity fixes land in some apps and not others. Visual and behavioural inconsistencies between apps. Mixed revisions inside one binary risk two copies of a type or protocol that disagree.
- **Recommended correction:** A release step (script plus CI check in nyx-packages) that fails when a shared crate appears at more than one revision, or at one older than its `main`, and bumps every app together. Longer term: a Cargo workspace or vendored path dependency for shared crates, built once.
- **Effort:** M
- **Dependencies:** NYX-DEP-001
- **Verification criteria:** `shared-crate-pins.txt` regenerated shows one revision per shared crate across all pinned apps.

### NYX-PKG-003: License metadata defaulted to MIT; six repositories have no license file

- **Component:** nyx-packages `lib/default.nix:188-191`; repos nyxos, nyx-packages, nyx-hyprland, nyx-wallpapers, nyx-calculator, nyx-transfer; `pkgs/zig_0_17.nix`, `pkgs/libghostty-vt.nix`, `pkgs/nyx-plymouth.nix`, `pkgs/nyx-wallpapers.nix`
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** partial
- **Description:** `buildWorkspace` sets `meta.license = lib.licenses.mit` for every Nyx package unless overridden. Only nyx-files overrides it (GPL-3.0-or-later). Six repositories carry no LICENSE/COPYING file. nyx-hyprland ships patches to BSD-3 Hyprland without a license statement. Some custom packages have no license or `sourceProvenance`: zig 0.17 is a prebuilt binary with neither; libghostty-vt, nyx-plymouth and nyx-wallpapers have none.
- **Expected:** §25 "Package metadata": accurate license, description and mainProgram. A license file in each distributed repository.
- **Actual:** `find REPO -maxdepth 1 -iname 'LICEN*' -o -iname 'COPYING*'` finds nothing in the six repositories listed. Cargo manifests say `license = "MIT"` for the Rust apps, so the MIT default is right for them.
- **Reproduce / verify:** as above; `grep -L license pkgs/*.nix`
- **Evidence:** as above
- **Affected versions:** current `main` of each
- **User impact:** Unclear redistribution terms for the OS repository, artwork and patch series.
- **Recommended correction:** Add LICENSE files. Set `meta.license` explicitly per package (no default). Add `sourceProvenance = binaryNativeCode` to zig_0_17.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Every repository has a license file; `nix eval` of each package's `meta.license` is explicit.

### NYX-PKG-004: Prebuilt third-party binaries and a CUDA path CI never builds

- **Component:** nyx-packages `pkgs/llama-prism-cuda.nix`, `pkgs/ntgcalls.nix`, `pkgs/zig_0_17.nix`, `modules/nixos/default.nix:64-75`
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Three upstream binaries are used as shipped. llama-prism-cuda is PrismML's prebuilt CUDA 12.8 tarball, unfree, patched with autoPatchelf. ntgcalls 3.0.5 is a prebuilt WebRTC `.so` loaded into Nyx Pulse. zig 0.17.0 is a prebuilt compiler that builds libghostty-vt for Nyx Agents. All are hash-pinned. The CUDA worker is built only by the NixOS module with the system's nixpkgs (`modules/nixos/default.nix:69`), so no CI ever builds or starts it. tdlib is built from source (`pkgs/tdlib_1_8_67.nix`), not prebuilt.
- **Expected:** §12 "Third-party binaries", §25 "Build provenance".
- **Actual:** as above. ntgcalls and llama-prism-cuda declare `sourceProvenance = binaryNativeCode`; zig does not.
- **Reproduce / verify:** read the three files.
- **Evidence:** as above
- **Affected versions:** nyx-packages `d69e87e`
- **User impact:** NVIDIA users get an AI worker no automated check has built. Binary blobs can't be rebuilt or audited.
- **Recommended correction:** Add a CI job that builds `llama-prism-cuda` with `allowUnfree` and a smoke test (`llama-server --version`). Track upstream source builds (ntgcalls from source when feasible). Mark zig's provenance.
- **Effort:** S
- **Dependencies:** NYX-DEP-004
- **Verification criteria:** CI log shows a CUDA worker build. `meta.sourceProvenance` set on all three.

### NYX-PKG-005: Release builds are stripped; no debug symbols for crash reports

- **Component:** nyx-packages `lib/default.nix:156-158` (release profile "thin LTO, stripped")
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Every Nyx Rust package builds the stripped release profile, with no `separateDebugInfo`. Core dumps from shell components and apps on NyxOS can't be symbolized.
- **Expected:** §25 "Debug symbols where appropriate".
- **Actual:** no `separateDebugInfo` in `lib/` or `pkgs/` (`rg separateDebugInfo` finds nothing).
- **Reproduce / verify:** `rg -n separateDebugInfo ~/Projects/nyx-packages`
- **Evidence:** `lib/default.nix:156-158`
- **Affected versions:** all
- **User impact:** Crashes (for example the Notification Center SIGABRT in `nyxos/docs/handoff.md`) are hard to diagnose from user reports.
- **Recommended correction:** Build with debuginfo and `separateDebugInfo = true` for shell components and daemons, and enable `environment.enableDebugInfo` or a debuginfod for the Nyx cache.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `coredumpctl info` on a Nyx crash shows function names.

### NYX-PKG-006: Runtime code still assumes host paths outside the package

- **Component:** nyx-biometrics `crates/nyx-authctl/src/enroll.rs:10-27`, `crates/nyx-auth-core/src/system.rs:15-41`; nyx-packages `pkgs/nyx-settings.nix:26`, `pkgs/nyx-store.nix:11-12`
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Shipped binaries hard-code `/usr/bin/pkexec`, `/usr/bin/fprintd-enroll`, `/usr/bin/irlume`, `/usr/lib/nyx-biometrics/...` and so on. A runtime fallback maps these to `/run/wrappers/bin` and `/run/current-system/sw` (`system.rs:15-31`). Settings relies on `nmcli`, `systemctl` and `hyprctl` "from the system" (`nyx-settings.nix:26`) without declaring them. Store links libalpm (`pacman_7_1`) and carries AUR/BlackArch code on NyxOS (`nyx-store.nix:11-12`). Peer identification still trusts `~/.local/bin` (`system.rs:35-41`); that one is for the security review.
- **Expected:** §25 "Identify packages that depend on undeclared host state".
- **Actual:** as above. The `installServices` guard (`lib/default.nix:118-130`) protects unit and D-Bus files but not paths inside binaries.
- **Reproduce / verify:** `rg -n '"/usr/(bin|lib)/' nyx-biometrics/crates nyx-settings/apps --type rust`
- **Evidence:** as above
- **Affected versions:** nyx-biometrics `1fe62af`, nyx-settings `7e76622`, nyx-store `fc2bdca`
- **User impact:** Static; confirm at runtime. A path the fallback misses fails only on NyxOS.
- **Recommended correction:** Patch tool paths at build time (`substituteInPlace` with store paths) or resolve through `PATH`. Declare runtime tools. Build Store without the alpm feature on NyxOS.
- **Effort:** M
- **Dependencies:** SEC review of `suite_program`
- **Verification criteria:** `strings` on shipped binaries shows no `/usr/bin/` paths, or each is covered by a NixOS test.

### NYX-CI-001: Distribution CI has been red for two days at a format check, so nothing is built or tested

- **Component:** nyxos `.github/workflows/ci.yml:39-40`; nyx-packages `.github/workflows/ci.yml:39-40`
- **Category:** CI
- **Severity:** P1
- **Status of feature:** implemented, not verified
- **Description:** Both workflows run `nix fmt --check` first. Unformatted files are pushed repeatedly, so every run fails within about 20 s and the build job never starts. nyx-packages has had no build since `8ecfdc7` (2026-11-10 18:41Z): 34 of the 35 runs since then failed (all sampled failures were the Format step; one run has no conclusion). nyxos's last green run was `e7a4a92` (2026-11-11 05:26Z). The `v0.1.0` pre-release tag (`d632770`) and nyx-packages `stable` (`558453c`) both failed at Format, so CI never built them.
- **Expected:** §26: "CI failures block unsafe publication"; "Release artifacts are traceable to source revisions".
- **Actual:** see the table above. Failing files on the latest runs: nyx-packages `lib/default.nix` and `pkgs/nyx-lyra.nix`; nyxos `iso/boot-menu.nix` and `modules/nixos/desktop.nix`.
- **Reproduce / verify:** `gh run list -R nyxos-project/nyx-packages -L 40`; `gh run view <id> --log-failed | grep 'not formatted'`
- **Evidence:** runs 43163810618 (nyx-packages), 43163843738 (nyxos), 42864747614 (nyx-packages `stable`)
- **Affected versions:** nyxos `main` since `e7a4a92`; nyx-packages `main` since `8ecfdc7`
- **User impact:** Build or test regressions in any app pinned since 10 November go unnoticed. The Cachix cache isn't filled for current `main`, so systems build locally. The release isn't validated.
- **Recommended correction:** Format before committing (pre-commit hook or `nix fmt` in the rebuild scripts). Make the Format step not gate the build: run it in a separate job so builds still run and report. Then require green CI before tagging.
- **Effort:** S
- **Dependencies:** NYX-CI-002
- **Verification criteria:** `main` of both repos green; the `v0.1.0` (or 0.1.x) tag sits on a commit with a green full build.

### NYX-CI-002: No branch protection; `stable` is promoted by hand with no gate

- **Component:** GitHub settings of nyxos-project/nyxos, nyxos-project/nyx-packages and sampled app repos; nyxos `README.md:37-40`; nyx-system `docs/updates.md:150-161`
- **Category:** CI
- **Severity:** P1
- **Status of feature:** partial
- **Description:** `main` and `stable` have no branch protection and no rulesets in either distribution repository. Org rulesets are unavailable on the free plan (HTTP 403). Sampled app repos (nyx-core, nyx-files, nyx-shell) are unprotected too. `stable` and `testing` move by manual push; no script or workflow promotes them and none checks CI first. Docs assume gates that don't exist: "branch protection decides which checks" and "stable moves when the known-good process promotes it" (`nyx-system/docs/updates.md:154,160`). Actions may approve pull requests (`can_approve_pull_request_reviews: true`) and any action is allowed (`allowed_actions: all`).
- **Expected:** §26: "CI failures block unsafe publication", "Branch protections", "Publishing permissions".
- **Actual:** `gh api repos/nyxos-project/nyxos/branches/main/protection` gives 404 "Branch not protected", and the same for `stable` and for nyx-packages. `gh api repos/.../rulesets` returns `[]`. `stable` = `known-good/22` = `7454358`; nyx-packages `stable` = `558453c`, whose own CI failed. In practice the nyxos `stable` push was green because nyxos CI built the systems.
- **Reproduce / verify:** the `gh api` calls above
- **Evidence:** as above
- **Affected versions:** current settings
- **User impact:** A push (or a compromised token) can put an untested or broken system on the channel every installed machine updates from.
- **Recommended correction:** Protect `stable` (and `main`) in both repos: require the CI checks, no force-push. Promote `stable` only through a workflow that verifies a green nyxos CI run on the exact commit, tags `known-good/N`, and moves nyx-packages `stable` to the pinned revision. Turn off `can_approve_pull_request_reviews`.
- **Effort:** S
- **Dependencies:** NYX-CI-001
- **Verification criteria:** `gh api .../branches/stable/protection` returns required status checks; a promotion workflow exists and refuses a red commit.

### NYX-CI-003: `stable` is behind 0.1.0, so a 0.1.0 install moves backwards on its first update

- **Component:** nyxos `templates/host/flake.nix:5-6`; nyx-installer `crates/nyx-install/src/plan.rs:286-293,355-356`; branch `stable`
- **Category:** reliability
- **Severity:** P1
- **Status of feature:** implemented, not verified
- **Description:** The installer pins the machine's flake to the live USB's NyxOS (`--override-input nyxos <src>`, `plan.rs:291`). The machine's channel URL is `github:nyxos-project/nyxos/stable` (`plan.rs:356`, default channel `stable`, `plan.rs:521`). `stable` is `7454358` (2026-11-10), 40 commits behind `v0.1.0` (`d632770`) and older than the `VERSION` file the release is named by. A machine installed from a 0.1.0 USB that runs `nyx update system` (a `flake update`) moves to the older `stable`.
- **Expected:** §26 release traceability; §23 updates: an update never downgrades the distribution.
- **Actual:** `git rev-list --count origin/stable..v0.1.0` gives 40; `git cat-file -e origin/stable:VERSION` fails.
- **Reproduce / verify:** as above; on a test install from the 0.1.0 USB, `nyx update system`, then read `/etc/os-release`.
- **Evidence:** as above
- **Affected versions:** nyxos `v0.1.0`, `stable` `7454358`
- **User impact:** Static; confirm at runtime. A first update silently reverts the Nightfall identity, boot menu and installer-era fixes, and may change settings formats.
- **Runtime result (install test):** on a fresh 0.1.0 install (machine flake on `stable`), `nyx update --dry-run` reported "Nothing to update": the system did not move backwards. Apps installed per user come from `github:nyxos-project/nyxos/stable` and were the 2026-11-09 builds, older than the 2026-11-11 apps built into the system (installation.md; evidence/logs/installed-update-dryrun.txt, installed-per-user-apps-2.txt). Severity stays P1: the channel the installer writes doesn't contain the release.
- **Recommended correction:** Promote `stable` to the release commit, after green CI, before publishing a USB image. Make the update path refuse an older channel head than the running system.
- **Effort:** S
- **Dependencies:** NYX-CI-001, NYX-CI-002; UPD findings
- **Verification criteria:** `stable` contains `v0.1.0`; a 0.1.0 install updated to `stable` reports 0.1.0 or later.

### NYX-CI-004: App CI mostly never runs; 16 core repositories have none

- **Component:** `.github/workflows/check.yml` in 31 app repos; repos without workflows (listed in `inventory.md`)
- **Category:** CI
- **Severity:** P2
- **Status of feature:** partial
- **Description:** 31 repositories' checks trigger only on `pull_request` and `workflow_dispatch`, but work is pushed straight to `main`. Their checks last ran on 2026-11-02 to 11-04 and were failing then (nyx-settings 5 of 5, nyx-assistant 4 of 4). Only nyx-bar, nyx-greeter, nyx-desktop-widgets and nyx-notes run tests on push, and nyx-notes fails every push. nyx-files and nyx-cloud only build, and nyx-cloud has failed since 2026-11-02. These have no CI at all: nyx-shell, nyx-system, nyx-ai, nyx-voice, nyx-installer, nyx-welcome, nyx-dock, nyx-control-center, nyx-notification-center, nyx-switcher, nyx-share, nyx-backup, nyx-clipboard, nyx-hyprland, nyx-plymouth, nyx-wallpapers. No QML is tested anywhere. App CI also targets Arch (container digest `e43f1fd…`), not NixOS.
- **Expected:** §26 "Test workflows", "Tests run on required targets".
- **Actual:** trigger table above; `gh run list -R design-nexus/<repo> -L 5`.
- **Reproduce / verify:** as above
- **Evidence:** workflows under each repo's `.github/workflows/`
- **Affected versions:** current `main`
- **User impact:** The only automated tests for most of the desktop are the narrowed ones inside nyx-packages builds, and those are blocked (NYX-CI-001).
- **Recommended correction:** Add `push: branches: [main]` to every `check.yml`. Add a minimal check workflow (build, `cargo test --workspace`, `qmllint`) to the 16 repos without one. Fix nyx-notes and nyx-cloud.
- **Effort:** M
- **Dependencies:** NYX-PKG-001
- **Verification criteria:** Each shipped repo shows a push-triggered green run on its current `main`.

### NYX-CI-005: The installer image isn't built by CI and the release has no artifacts or provenance

- **Component:** nyxos `flake.nix:166-184` (checks), `flake.nix:94-97` (`packages.iso`); GitHub release `v0.1.0`
- **Category:** CI
- **Severity:** P2
- **Status of feature:** partial
- **Description:** The checks CI builds cover `incus-dev`, `installed`, `catalog`, `nyx-cli` and the tools, but not `packages.iso`. The 0.1.0 pre-release (2026-11-12) has no assets. The ISO is built on a developer machine with no checksum, signature or attestation tying it to a commit. Cachix trust is the only provenance for binaries, and every install trusts the cache (`modules/nixos/base.nix:19-20`). Anyone who can push to `main`, `stable` or a same-repo PR branch in nyx-packages fills that cache without review.
- **Expected:** §26 "Release workflows", "Artifact retention", "Release artifacts are traceable to source revisions"; §12 "Release signing where implemented".
- **Actual:** `gh release view v0.1.0 -R nyxos-project/nyxos --json assets` gives `[]`.
- **Reproduce / verify:** as above
- **Evidence:** as above
- **Affected versions:** `v0.1.0`
- **User impact:** Users can't verify an image they download. A broken ISO evaluation or build isn't caught.
- **Recommended correction:** Add `iso` to checks, or a release workflow that builds it from the tag. Publish it with SHA256SUMS, a signature and a GitHub artifact attestation. Restrict Cachix pushes to protected branches.
- **Effort:** M
- **Dependencies:** NYX-CI-001, NYX-CI-002
- **Verification criteria:** A tagged release carries an ISO built by CI from that tag, with checksums and a verifiable attestation.

### NYX-CI-006: Proposed updates sit unreviewed

- **Component:** nyxos pull requests #1–#10
- **Category:** CI
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Eight tool-update PRs (opened 2026-11-08) and two Dependabot action bumps (2026-11-10) are open. Several tool-update PR runs show `action_required` (approval needed), though the dispatched CI runs on those branches passed. The update pipeline is sound (NYX-CI notes above), but without review the pins age, including AI CLIs that talk to cloud services.
- **Expected:** §26 "Package update automation", "Dependency monitoring".
- **Actual:** `gh pr list -R nyxos-project/nyxos`
- **Reproduce / verify:** as above
- **Evidence:** as above
- **Affected versions:** n/a
- **User impact:** Users run older third-party tools than the channel could offer.
- **Recommended correction:** Review weekly, or opt low-risk tools into `autoMerge` once branch protection exists (NYX-CI-002).
- **Effort:** S
- **Dependencies:** NYX-CI-002
- **Verification criteria:** No update PR older than a week.

### NYX-CI-007: `dev-vm packages` copies the VM's lock back over the checkout

- **Component:** nyxos `scripts/dev-vm` (`packages` command, `pull_lock`)
- **Category:** CI
- **Severity:** P3
- **Status of feature:** verified (observed during this audit's Phase C run)
- **Description:** `scripts/dev-vm packages <nix args>` pushes `../nyx-packages` into the VM, runs nix there, then copies the VM's `flake.lock` back over the host checkout unconditionally.
- **Expected:** A read-only command (`flake check`, `build`) leaves the host checkout alone; a lock is copied back only when nix changed it in the VM.
- **Actual:** `scripts/dev-vm:163-169`. During the audit another session changed `nyx-files` in the host's lock while the check ran; the copy-back would have reverted it. Avoided by deleting the VM's copy after evaluation (evidence/runtime-notes.md).
- **Reproduce / verify:** edit the host lock while `scripts/dev-vm packages flake check` runs; the edit is gone afterwards.
- **Evidence:** `scripts/dev-vm:66-70,163-169`
- **Affected versions:** nyxos `97f1573`
- **User impact:** Developers only; silent loss of another session's lock update, which then ships stale pins.
- **Recommended correction:** Hash the lock before pushing and copy it back only if the VM's differs from what was pushed; refuse if the host's changed meanwhile.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The reproduction above keeps the host edit.

### NYX-PKG-008: Two Nyx apps that start session services can't both be installed per user

- **Component:** nyx-packages `lib/default.nix:180` (`> $out/share/nyx/autostart`)
- **Category:** packaging
- **Severity:** P1
- **Status of feature:** verified (installed system)
- **Description:** Each app with session units writes the same file, `share/nyx/autostart`. A Nix profile can't hold two packages providing the same file, so installing a second such app per user (as Welcome and the Store do since `standaloneApps = "per-user"`) fails.
- **Expected:** Welcome's "Nyx apps" step installs any combination it offers (handoff 09; release inventory tier 2).
- **Actual:** On the installed VM, `nyx-system catalog install calendar mail --yes`: Calendar installs; Mail fails with "An existing package already provides the following file: …nyx-calendar…/share/nyx/autostart … conflicting file from the new package: …nyx-mail…/share/nyx/autostart". Packages with the file: Welcome tier Calendar, Mail, Passwords, Home, Assistant; Store tier Reminders, Clipboard, Transfer, Cloud.
- **Reproduce / verify:** On a fresh install, `nyx-system catalog install calendar mail --yes`.
- **Evidence:** evidence/logs/installed-per-user-apps.txt, installed-per-user-apps-2.txt
- **Affected versions:** nyx-packages 6841d40 and later (d69e87e; also the `stable` channel's builds)
- **User impact:** Choosing Mail and Calendar (or any two of the nine) in Welcome fails partway; the second app is missing.
- **Recommended correction:** Name the file per package (`share/nyx/autostart.d/<pname>`) and read the directory in the activation script (`modules/nixos/default.nix:118-125`).
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `nyx-system catalog install calendar mail passwords home --yes` succeeds per user and each app's units start at the next sign-in.

### NYX-PKG-009: Apps installed per user have no D-Bus activation or `nyx` actions until something else wires them

- **Component:** nyx-packages `modules/nixos/default.nix` (system-only `services.dbus.packages`, actions in `/run/current-system/sw/share/nyx`); nyx-core `nyx-actions`
- **Category:** packaging
- **Severity:** P2
- **Status of feature:** verified (installed system)
- **Description:** Right after a per-user install of Calendar: its D-Bus name isn't activatable (only system packages' names are), `nyx calendar` is "not a recognised command" (the actions registry lists only system apps), and `nyx-calendard` is linked but disabled until the next sign-in. The Glimpse plugin is in `~/.nix-profile/share/nyx-calendar/glimpse`.
- **Expected:** An app installed from Welcome or the Store behaves like a system one: Glimpse, `nyx APP`, the Assistant and D-Bus activation find it (handoff 05 shared actions).
- **Actual:** evidence/logs/installed-per-user-apps.txt (activatable names, `nyx apps` output).
- **Reproduce / verify:** Install an app per user; `busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ListActivatableNames`; `nyx apps`.
- **Evidence:** as above; static: apps/mail.md MAIL-002, apps/calendar.md CALENDAR-002
- **Affected versions:** nyx-packages d69e87e
- **User impact:** Since new installs put Welcome apps in the user's profile, the integrations the suite advertises (actions, Assistant, activation) don't work for them.
- **Recommended correction:** Add the profile's `share/dbus-1/services` and `share/nyx` to the session's search paths (`XDG_DATA_DIRS` already includes the profile; check dbus-broker's service dirs and nyx-actions' lookup), and start new units immediately after install.
- **Effort:** S–M
- **Dependencies:** NYX-PKG-008
- **Verification criteria:** After a per-user install, without signing out, `nyx calendar --help` works and the app's D-Bus name activates.
