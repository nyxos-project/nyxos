# Nyx Welcome scorecard

- **Repository:** nyxos-project/nyx-welcome at `1094052384` (pinned in nyx-packages: yes, 0 behind origin/main)
- **Release tier:** base (`nyx.welcome.enable`)
- **Purpose:** setup after installation: theme, computer, catalog presets and sections, default apps, accounts, updates; one System Manager apply at the end
- **Stack:** Rust/GTK4; zbus client of the Nyx System Manager (`nyx-system-proto`, system bus); `nyx-catalog` for software, Flatpak and Nix profile installs
- **Binaries / services:** `nyx-welcome`; user unit `nyx-welcome.service` started with `graphical-session.target` (`passthru.autostart`), desktop entry, icon (`nyx-packages/pkgs/nyx-welcome.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | All 13 steps implemented; one rebuild through the System Manager, then Flathub and Nix profile, then the optional update |
| UX | 2 | Skippable steps with marks, consent checkboxes, progress with details; can be closed mid-apply without a word |
| Accessibility | 2 | Text buttons throughout; 1 icon button site, 3 tooltips |
| Reliability | 2 | Failures stop with the step and reason, retry re-plans what's left; not single-instance |
| Integration | 3 | System Manager, catalog, Settings pages, Store hand-off; first-run unit from the package |
| Packaging | 3 | Unit from the repository with its PATH set by the module; tests on a private bus |
| Maintainability | 1 | 3 tests for the app that applies a new install's system changes; no CI workflow |

## Functionality

- **At first sign-in.** The user unit runs `nyx-welcome --first-run` (`apps/welcome/data/nyx-welcome.service:8`), which exits at once when `~/.config/nyx/welcome.toml` says setup was finished (`apps/welcome/src/main.rs:54-56`, `state.rs:16-33`). Until then it opens at every sign-in.
- Steps (`apps/welcome/src/steps/mod.rs:38-53`): Welcome, Appearance, Computer and desktop, Starting point (presets), six catalog sections, Default apps, Accounts and sign-in, Updates and recovery, Review. Skipping removes that step's choices (`steps/mod.rs:70-93`).
- Theme, default apps and accounts apply right away; hostname, time zone, keyboard and boot/login theme become System Manager changes at Review (`steps/review.rs:16-32`) together with the catalog plan (`:51-60`).
- **Apply.** One stage list: `Apply` or `ApplyAndUpdate` on the System Manager, then Flathub, then Nix profile (`review.rs:212-227`), each over `system::run` (`system.rs:28-87`). Consent items (unfree licences, services, groups) must each be ticked before Apply is enabled (`review.rs:114-133`). An unreachable System Manager shows a banner (`review.rs:62-72`).
- **Failure handling.** The failed stage is named with the reason, the log stays in Details, and "Try Again" refreshes what's installed and plans only what's left (`review.rs:246-296`). Setup is marked done only after everything worked (`review.rs:299-304`).

## UX and accessibility (static)

- Footer Back / Skip / Next with tooltips (`window.rs:232-238`); a step list with Done/Skipped marks (`window.rs:107-117`).
- Theme colours checked by a test (`main.rs:70-75`); no hard-coded colours.
- Closing the window while applying isn't intercepted (`main.rs:38-41`); `busy` only blocks navigation (`window.rs:66`).

## Reliability

- No `unwrap()` outside tests; one `expect`, one `unreachable!` for job kinds handled earlier (`system.rs:81`).
- `ApplicationFlags::NON_UNIQUE` (`main.rs:63`): the first-run copy and one opened from the launcher run side by side, each able to start an apply.
- Unit `Type=exec` without `Restart=`; a crash leaves setup unfinished, so it opens again at the next sign-in.

## Integration and packaging

- No Omarchy references. Pins: nyx-core `4378e24` (main `9187295`), nyx-design `40db521` (main `e311c2f`), nyx-system `8514a6d` (main `6f0c47c`); the installer pins nyx-system `8e723ee`.

## Maintenance

- 3 tests (step list covers the catalog, system changes validate, theme colours). README (50 lines) matches the code. No `.github/workflows`.

## Runtime results

- Smoke test (Welcome): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- On the installed system Welcome opens at the first sign-in on its first page (14 steps) (shots/installed-first-login.png). 'Review and apply' not exercised end to end.

## Findings

### NYX-APP-WELCOME-001: Setup's apply path has almost no tests and no CI

- **Component:** nyx-welcome `apps/welcome/src/steps/review.rs`, `system.rs`
- **Category:** CI
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** The code that turns a new install's choices into System Manager changes, Flatpak and Nix profile installs, and the retry path, has one unit test (`review.rs:341-356`) and no repository CI.
- **Expected:** The first-run path of every install is tested (installation is release-blocking on the audit's severity scale, `../evidence/FINDINGS-FORMAT.md`).
- **Actual:** 3 tests in total; no `.github/workflows`.
- **Reproduce / verify:** `rg -c '#\[test\]' nyx-welcome`.
- **Evidence:** as above.
- **Affected versions:** `1094052384`
- **User impact:** Regressions in first-run setup are found by new users.
- **Recommended correction:** Test `run`'s stage order and retry planning against a fake System Manager on the private bus the package already uses (`nyx.privateBusPreCheck`).
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** Tests cover apply success, a failed stage and a retry that skips finished work.

### NYX-APP-WELCOME-002: Welcome can run twice and be closed mid-apply without warning

- **Component:** nyx-welcome `apps/welcome/src/main.rs:38-41,63`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `NON_UNIQUE` lets the first-run window and a launcher copy coexist; closing during apply drops the Flathub and Nix profile stages that hadn't started (the System Manager's rebuild continues on its own).
- **Expected:** One Welcome; closing while busy asks first or keeps the work running.
- **Actual:** see Component.
- **Reproduce / verify:** Open Welcome from the launcher while the first-run copy is open; close during "Building…" (static; confirm at runtime).
- **Evidence:** as above.
- **Affected versions:** `1094052384`
- **User impact:** Some chosen apps silently not installed until Welcome is reopened (it reopens at next sign-in, which recovers).
- **Recommended correction:** Make it unique (present the existing window) and confirm closing while `busy`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A second launch focuses the first window; closing while busy asks.
