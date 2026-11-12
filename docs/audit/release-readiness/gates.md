# Release gate checklist (handoff 10 section 33)

Status as of 2026-11-12, nyxos `97f1573` / nyx-packages `d69e87e` (tag `v0.1.0` is
`d632770`, 1 commit earlier in nyxos). A gate passes only on evidence from this audit.
Experimental and deferred features ([remediation.md](remediation.md) "Deferred") are
excluded from every gate.

| Gate | Status | Why |
| --- | --- | --- |
| A. Build integrity | **Pass at the pinned revisions; not enforced** | nyxos and nyx-packages flake checks and the ISO build pass from a clean evaluation ([build-report.md](build-report.md)); but CI is red on every push since 10 Nov and nothing blocks an unbuilt revision from `main` or `stable` (NYX-CI-001, NYX-CI-002) |
| B. Installation | **Fail** | The 0.1.0 ISO can't install (NYX-INST-001, P0); no physical hardware tested (NYX-HW-001) |
| C. Core desktop | **Fail (conditional)** | Login, shell, compositor, settings, networking and apps work in the VM; failing: system changes stop working a week after install (NYX-INST-002), two Welcome apps can't both install (NYX-PKG-008), new monitors get no bar/dock (NYX-REL-003), shell crash loop leaves no recovery path (NYX-SHELL-001) |
| D. Security | **Pass with conditions** | No authentication bypass or critical vulnerability found; lock chain robust; P2 issues to fix or document: unauthenticated AI endpoint (NYX-SEC-001), spoofable app identity (NYX-SEC-002), Connect port open on every network (NYX-SEC-003), `input` group (NYX-SEC-004), passwordless recovery shell (NYX-SEC-005) |
| E. Data integrity | **Not verified** | No data-loss defect reproduced; Backup restore verified (local, separate folder); but Office's in-place save of Word/Excel/PowerPoint files may drop content (NYX-APP-OFFICE-001, untested), and scheduled backups stop after garbage collection (NYX-APP-BACKUP-001) |
| F. Updates and recovery | **Fail** | Rollback and failed-build undo work; but the installed channel is behind the release (NYX-CI-003), system changes break after GC (NYX-INST-002), an interrupted change isn't undone (NYX-REL-002), `stable` promotion has no gate (NYX-CI-002) |
| G. UX and accessibility | **Fail** | Assistive technology disabled system-wide (NYX-A11Y-001); default theme fails WCAG AA for secondary text (NYX-THEME-002, NYX-A11Y-002); shell surfaces keyboard/screen-reader gaps (NYX-SHELL-005) |
| H. Documentation | **Fail** | No installation guide, hardware requirements, troubleshooting, recovery guide or known-limitations page (NYX-DOC-001); 28 READMEs still describe Omarchy (NYX-DOC-002) |
| I. Release inventory | **Fail** | Advertised features that don't work as advertised: Podman in Containers (CONTAINERS-001), Passwords autofill (PASSWORDS-001), Mail's Google/Microsoft without registering an OAuth app (MAIL-001), Assistant opening apps by voice (ASSISTANT-001), nearby sharing to NyxOS (SHARE-001) |

## Exit criteria per gate

**A. Build integrity**
- [ ] CI green on `main` for nyxos and nyx-packages, building every check (including the ISO).
- [ ] Branch protection on `main` and `stable` requires CI; `stable` moves only to a green, tagged revision.
- [ ] The release tag's commit has a green CI run linked from the release.

**B. Installation**
- [ ] NYX-INST-001 fixed; an automated install test (headless plan) runs in CI against the built ISO.
- [ ] Graphical install completes on two physical laptops (one Intel, one AMD) and one VM, erase and beside-Windows, with a non-US keyboard layout (NYX-APP-INSTALLER-001).
- [ ] First boot reaches the greeter; sign-in reaches Welcome.

**C. Core desktop**
- [ ] NYX-INST-002, NYX-PKG-008, NYX-REL-003 fixed and retested.
- [ ] Shell recovers from a crash loop without a terminal (NYX-SHELL-001).
- [ ] Smoke test opens every launcher entry (helper entries hidden: NYX-UX-001).

**D. Security**
- [ ] No open P0/P1 security findings (currently none).
- [ ] NYX-SEC-001..005 fixed or explicitly accepted with documented mitigations in a security model page (NYX-DOC-005).

**E. Data integrity**
- [ ] Office round-trip test of real .docx/.xlsx/.pptx files: either lossless for common files or Save in place refuses/warns (NYX-APP-OFFICE-001).
- [ ] Scheduled backup still runs after an update and `nix-gc` (NYX-APP-BACKUP-001).
- [ ] Backup restore to the original location verified on NyxOS.

**F. Updates and recovery**
- [ ] The installer's channel contains the release (NYX-CI-003); a 0.1.0 install updates forward.
- [ ] System changes work after `nix-gc` on a fresh install (NYX-INST-002).
- [ ] Interrupted change leaves the system and overrides consistent (NYX-REL-002).
- [ ] Recovery boot entry tested (and protected: NYX-SEC-005).

**G. UX and accessibility**
- [ ] `services.gnome.at-spi2-core.enable = true`; Orca reads the greeter, Files and Settings (NYX-A11Y-001).
- [ ] Default theme passes 4.5:1 for all text roles and 3:1 for control borders (NYX-A11Y-002).
- [ ] Dock, bar and Control Center operable from the keyboard (NYX-SHELL-005).

**H. Documentation**
- [ ] Install guide, hardware requirements (tested list from [hardware.md](hardware.md)), recovery and rollback guide, troubleshooting, known limitations.
- [ ] READMEs of release-included apps describe NyxOS (NYX-DOC-002).

**I. Release inventory**
- [ ] Every catalog and Welcome description matches what works (fix or reword the five P1 app findings).
- [ ] Experimental items (Lyra, Pulse calls, Assistant voice) labelled as such or moved out of Welcome (see [remediation.md](remediation.md)).
