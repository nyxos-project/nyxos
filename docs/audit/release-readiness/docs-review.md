# Documentation review (handoff 10 §27)

Static review, 2026-11-12. Sources read: nyxos `README.md` and `docs/`, nyx-packages
`README.md` and `docs/compatibility.md`, the READMEs of all 66 repositories in
`inventory.md` that have one, nyx-installer, nyx-welcome, nyx-system (`README.md`,
`docs/updates.md`), nyx-backup `docs/`, nyx-biometrics `docs/THREAT_MODEL.md`, nyx-shell
`docs/SECURITY.md`, nyx `docs/desktop/`, the `design-nex.us` and `design-nexus.github.io`
site checkouts, and the GitHub release text for `v0.1.0`.

## Coverage

"Current?" means it describes NyxOS 0.1.0 as built, not Omarchy or a plan.

| Doc type | Exists? | Location | Current? | Gap |
| --- | --- | --- | --- | --- |
| Installation guide | No (fragments) | nyxos `README.md:8-14` (ISO name, Secure Boot off); nyx-installer `README.md` (10 lines, for developers); `v0.1.0` release notes | Partly | No step-by-step guide: how to get the image (the release has no ISO asset), write it to USB, firmware settings, dual boot, encryption passphrase, what the installer asks |
| Hardware requirements | No | none found (`rg -i 'requirement'` across nyxos, installer, welcome, system) | n/a | CPU/RAM/disk minimums, GPU support (Vulkan worker, NVIDIA CUDA option), UEFI/BIOS, Secure Boot, tested machines |
| First-run guide | Developer-level | nyx-welcome `README.md` (the 9 steps) | Yes | Not user-facing; nothing on accounts, keyring, biometrics enrolment, what's preselected |
| Settings documentation | No for NyxOS | nyx-settings `README.md` titled "Omarchy Settings", "A native control panel for Omarchy" | No | Page-by-page reference for NyxOS; README describes Lua file editing and the Omarchy install |
| CLI reference | Partial | nyxos `README.md:68-92` (`nyx` table); `nyx` usage text in `pkgs/nyx-cli/nyx.sh:4-29` | No | README says `install` runs `nix profile add nixpkgs#…`; the CLI actually goes through `nyx-system catalog install` (`nyx.sh:224-234`). README omits `update` targets, `display`, `apps`, `completion`; no man pages |
| Troubleshooting | No | only nyx-shell `docs/SECURITY.md` and `docs/agent-skills.md` mention it | n/a | Black screen, no network, failed update, GPU fallback, logs to collect (`journalctl`, `coredumpctl`) |
| Recovery | Partial | nyxos `README.md:65-66` (rollback one-liner); `modules/nixos/recovery.nix:1-4` comments; nyx-backup `docs/RECOVERY.md` | Partly | No user guide to the Recovery boot entry, generations, configuration repair; nyx-backup's RECOVERY.md doesn't mention NyxOS |
| Backup and restore | Yes (app-level) | nyx-backup `README.md`, `docs/RESTORE.md`, `docs/RECOVERY.md` | Partly | Written for the app on any distro (0 mentions of NyxOS); no link from NyxOS docs; how Backup relates to Btrfs snapshots (`modules/nixos/snapshots.nix`) unexplained |
| Updates | Yes (developer-level) | nyx-system `docs/updates.md` (thorough), nyxos `README.md:35-40` channels | Partly | Claims a "known-good process" and branch protection that don't exist (`updates.md:154,160`); no user page on channels, what `nyx update` does, or how to switch `stable`/`testing` |
| Developer setup | Yes | nyxos `docs/dev-vm.md`, nyx-packages `README.md` | Partly | dev-vm.md assumes an Omarchy/Arch host (`dev-vm.md:11-28`: ufw, `pacman -S`), says auto-login "until Nyx Greeter" and tuigreet (`:115-116`) though Nyx Greeter ships; nyx-packages README says Git deps are fetched at evaluation (`:112`), lib uses `git-hashes.json` |
| Architecture docs | Partly | nyx `docs/desktop/ARCHITECTURE.md` (35 KB), `inventory.md` and `release-inventory.md` of this audit, nyx-system `README.md` | No | ARCHITECTURE.md is "Phase 0: audit and architecture" of replacing Omarchy parts; no NyxOS architecture overview (flake layers, nyx-packages, System Manager, Shell Core, AI Core) |
| Security model | Component-level | nyx-biometrics `docs/THREAT_MODEL.md`, nyx-shell `docs/SECURITY.md`, nyx-backup `docs/SECURITY-REVIEW.md` | Partly | No NyxOS-level model: firewall defaults, polkit and System Manager authority, Cachix trust (`base.nix:19-20`), unsigned live USB, peer trust via `/etc/nyx/trusted-bin`; THREAT_MODEL.md doesn't mention NyxOS |
| Known limitations | Scattered | nyx-packages `README.md` table notes; nyxos `docs/handoff.md` "Known problems not fixed yet" (2026-11-07); nyx-backup README | No | No release-notes list of limitations for 0.1.0; the handoff list predates the release |
| Release notes | Yes | GitHub pre-release `v0.1.0` | Yes | No assets; no limitations section |
| Website | No NyxOS content | `design-nex.us` (last commit 2026-10-28), `design-nexus.github.io` | No | Neither mentions NyxOS (0 matches) |

## READMEs still written for Omarchy

Counted over the 66 READMEs of the repositories in `inventory.md` (nyx-hyprland and
nyx-themes have none):

- **28** describe the project as "for Omarchy" or "for [Omarchy](https://omarchy.org)" in
  their opening lines (regex `for \[?omarchy`, first 1,200 characters): nyx,
  nyx-activity, nyx-archive, nyx-assistant, nyx-biometrics, nyx-browser, nyx-calculator,
  nyx-calendar, nyx-capture, nyx-clipboard, nyx-control-center, nyx-dock, nyx-fonts,
  nyx-mail, nyx-maps, nyx-media-player, nyx-music, nyx-news, nyx-notepad,
  nyx-notification-center, nyx-office, nyx-pdf, nyx-photos, nyx-reminders, nyx-settings,
  nyx-store, nyx-switcher, nyx-torrents. 27 of them are shipped or packaged; nyx-browser
  isn't.
- 12 of those use the literal unlinked phrase "for Omarchy".
- **44** give only Arch/Omarchy install instructions (`install.sh`, `~/.local/bin`,
  `pacman`, AUR) and never mention NyxOS, Nix or nyx-packages.
- 39 mention Omarchy somewhere.

`inventory.md` says "23 READMEs open with 'for Omarchy'". Neither count reproduces it: the
literal phrase appears in 12, and the linked or unlinked form in 28.

Reproduce:

```sh
cd ~/Projects
for r in $(jq -r '.repos[].name' nyxos/docs/audit/release-readiness/evidence/inventory.json); do
  [ -f "$r/README.md" ] && head -c 1200 "$r/README.md" | grep -qiE 'for \[?omarchy' && echo "$r"
done | wc -l
```

## Currency of nyxos/docs

- `README.md:16` "Status: phase 1, a development VM that boots into the Nyx desktop", the
  same day a 0.1.0 pre-release with a live USB and installer was published. `README.md:17`
  links `docs/audit/repository-audit.md`, dated 2026-11-03.
- `docs/dev-vm.md`: host prerequisites in Omarchy and Arch terms (`:11-28`). Auto-login
  "temporary, until Nyx Greeter" and tuigreet after logout (`:115-116`), though Nyx Greeter
  is the greeter (`modules/nixos/desktop.nix:12-21`). The `incus-dev` comment says the same
  (`hosts/incus-dev/default.nix:21`). It also prints the VM's test password; a test
  password exists in `dev-vm.md` and `handoff.md`.
- `docs/handoff.md`: "where NyxOS stands (2026-11-07, night)". It predates the Catppuccin
  identity, the ISO, the installer, Lyra, Git 2.0 and 0.1.0, so its "Known problems" and
  "Waiting on Ken" lists are stale.

---

## Findings

### NYX-DOC-001: No user documentation for installing, requirements, troubleshooting or limitations

- **Component:** nyxos `README.md`; nyx-installer `README.md`; design-nex.us site
- **Category:** docs
- **Severity:** P2
- **Status of feature:** approved, not implemented
- **Description:** NyxOS 0.1.0 is published as a pre-release with an installer, but there's no installation guide, hardware requirements, troubleshooting guide or known-limitations list anywhere. The project website doesn't mention NyxOS.
- **Expected:** §27: installation guide, hardware requirements, troubleshooting, known limitations, "describe the current implementation".
- **Actual:** see the coverage table. nyx-installer `README.md` is 10 lines of developer description. `rg -i 'nyxos' design-nex.us/index.html design-nex.us/nyx/index.html` finds nothing.
- **Reproduce / verify:** read the files listed.
- **Evidence:** as above
- **Affected versions:** nyxos `v0.1.0`, `97f1573`
- **User impact:** A new user can't tell whether their machine is supported, how to make the USB, what to do when the GPU or network doesn't work, or what's known to be missing.
- **Recommended correction:** Add a `docs/user/` set in nyxos (install, requirements, first run, updates and channels, recovery, backup, troubleshooting, known limitations), published to the website and linked from the release notes.
- **Effort:** M
- **Dependencies:** NYX-CI-005 (an ISO to point to)
- **Verification criteria:** Each row marked "No" in the coverage table has a current page.

### NYX-DOC-002: 28 READMEs present the apps as Omarchy software, 44 give only Arch install steps

- **Component:** READMEs of the repositories listed above
- **Category:** docs
- **Severity:** P2
- **Status of feature:** deprecated
- **Description:** The repositories NyxOS ships still open by describing an Omarchy app, and most give only the curl-pipe `install.sh` into `~/.local/bin` or `pacman` steps. nyx-settings' README is titled "Omarchy Settings". On NyxOS those instructions are wrong: an `install.sh` install puts a second copy in `~/.local/bin` beside the Nix one.
- **Expected:** §27 "Documentation must describe the current implementation".
- **Actual:** counts and list above. For example `nyx-settings/README.md:1-3`, `nyx-dock/README.md:3-16` ("Installing doesn't replace Omarchy's dock").
- **Reproduce / verify:** the loop above.
- **Evidence:** as above
- **Affected versions:** current `main` of each
- **User impact:** NyxOS users following a README install a conflicting copy or look for Omarchy features. The project looks unfinished.
- **Recommended correction:** A README template with the NyxOS section first ("On NyxOS: in Welcome/Store, or `nyx install NAME`") and Omarchy as a secondary platform, if it's still supported. Apply it across all 44.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The count script returns 0 for the opening lines; each shipped README has a NyxOS install section.

### NYX-DOC-003: The distribution's own docs are stale

- **Component:** nyxos `README.md:16-17,68-92`; `docs/dev-vm.md:11-28,115-116`; `docs/handoff.md:1`; `hosts/incus-dev/default.nix:21`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** partial
- **Description:**
  - The README calls NyxOS "phase 1, a development VM".
  - The `nyx` command table no longer matches the CLI: install and remove go through the catalog and System Manager (`pkgs/nyx-cli/nyx.sh:224-240`), search covers the catalog, and several subcommands are missing.
  - dev-vm.md assumes an Omarchy host and describes auto-login and tuigreet from before Nyx Greeter.
  - handoff.md is dated before 0.1.0.
  - Test credentials are written in two docs (values not repeated here).
- **Expected:** §27 current implementation; §12 no credentials in docs.
- **Actual:** as cited.
- **Reproduce / verify:** read the lines.
- **Evidence:** as above
- **Affected versions:** nyxos `97f1573`
- **User impact:** Developers and agents act on outdated instructions. Readers see a contradictory project status.
- **Recommended correction:** Update the README status and CLI table (or generate the table from `nyx --help`). Rewrite dev-vm.md host prerequisites to be distro-neutral and drop the greeter notes. Date-stamp or retire handoff.md. Move test credentials out of docs, or mark them as the dev VM's only.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** README and dev-vm.md describe 0.1.0; `nyx --help` and the README table agree.

### NYX-DOC-004: Process docs promise CI gates and behaviour that don't exist

- **Component:** nyx-system `docs/updates.md:150-163`; nyx-packages `README.md:43,50,110-112,135-137`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** partial
- **Description:**
  - updates.md says auto-merge depends on "branch protection decides which checks" and "`stable` moves when the known-good process promotes it". No branch protection or promotion process exists (NYX-CI-002).
  - The nyx-packages README says "CI builds and tests both branches and pushes the results", but both have failed since 10 November and `stable` never passed.
  - It says Git dependencies are fetched at evaluation time (`allowBuiltinFetchGit`), but `lib/default.nix:82-104` uses pinned hashes.
  - It says 82 Files tests are skipped (there are 83).
  - It says Passwords has "no polkit sign-in or TPM broker until Nyx Biometrics is packaged", but Biometrics is packaged.
- **Expected:** §27 current implementation; §26 traceability.
- **Actual:** as cited.
- **Reproduce / verify:** compare with `gh api …/branches/stable/protection`, `lib/default.nix`, `pkgs/nyx-files-skipped-tests.txt`.
- **Evidence:** as above
- **Affected versions:** nyx-system `6f0c47c`, nyx-packages `d69e87e`
- **User impact:** Maintainers believe safeguards exist that don't.
- **Recommended correction:** Fix the text now, or implement the gates (NYX-CI-002) and keep the text.
- **Effort:** S
- **Dependencies:** NYX-CI-001, NYX-CI-002
- **Verification criteria:** Each statement checks out against settings and code.

### NYX-DOC-005: No NyxOS-level architecture or security model

- **Component:** nyx `docs/desktop/ARCHITECTURE.md`; nyx-biometrics `docs/THREAT_MODEL.md`; nyx-shell `docs/SECURITY.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Architecture and security docs exist per component, and the main architecture document describes replacing Omarchy's shell ("Phase 0"). Nothing describes NyxOS as a whole. Missing: the configuration layers and flakes, nyx-packages and channels, the System Manager's polkit authority, Shell Core, AI Core's local API, the trusted-bin peer model, the binary cache trust, and the unsigned live USB.
- **Expected:** §27 "Architecture documentation", "Security model".
- **Actual:** `head nyx/docs/desktop/ARCHITECTURE.md` shows "# Nyx Desktop — Phase 0: audit and architecture … What Omarchy 4.5 already runs". THREAT_MODEL.md has 0 mentions of NyxOS.
- **Reproduce / verify:** as above
- **Evidence:** as above
- **Affected versions:** current
- **User impact:** Reviewers and contributors can't assess the system's trust boundaries.
- **Recommended correction:** Add `nyxos/docs/architecture.md` and `nyxos/docs/security.md` built from `inventory.md`, `release-inventory.md` and the SEC findings of this audit.
- **Effort:** M
- **Dependencies:** SEC and ARCH findings
- **Verification criteria:** Both documents exist and match the shipped modules.
