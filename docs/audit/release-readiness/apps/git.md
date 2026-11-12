# Nyx Git scorecard

- **Repository:** design-nexus/nyx-git at `84deb0895a` (pinned in nyx-packages: yes, 0 commits behind origin/main)
- **Release tier:** welcome ("Git repositories, changes and history.")
- **Purpose:** visual Git client: commit graph, staging, worktrees, submodules, LFS, conflict and interactive-rebase studios, hosting reviews
- **Stack:** Rust/GTK4, GtkSourceView 5, the `git` CLI (no libgit2), hosting providers with tokens in the Secret Service, nyx-actions (API 2)
- **Binaries / services:** `nyx-git` (`nyx-packages/pkgs/nyx-git.nix`: `actions = [ "nyx-git" ]`, runtime `git`, `git-lfs`, `openssh`, `libsecret`, `xdg-utils`, `xdg-terminal-exec`; tests run serially because of a per-repository flock); option `nyx.git.enable` (`modules/nixos/default.nix:22`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Full daily workflow plus advanced ops, recovery points and operation history; no stubs |
| UX | 3 | Welcome page with no repo, palette, previews before destructive ops, clear failure text |
| Accessibility | 3 | 67 tooltips and 72 explicit accessible labels |
| Reliability | 3 | 69 non-test unwraps, nearly all GTK widget-structure downcasts (`ui/changes.rs:113-220`); fresh-state guards on every advanced op |
| Integration | 2 | Actions manifest, Glimpse `git` panel; HTTPS/SSH auth relies on helpers NyxOS doesn't configure |
| Packaging | 3 | All runtime tools on PATH; pinned |
| Maintainability | 3 | 63 tests, check.yml CI, 290-line README |

## Functionality

- Destructive operations (`apps/git/src/core/advanced.rs`):
  - Every advanced action is re-validated against a fresh snapshot ("The repository changed after this action was prepared…", `advanced.rs:113`).
  - A recovery ref `refs/nyx/recovery/<stamp>` is written before history-rewriting ops; errors point to it (`advanced.rs:330-336,706-777`); Recovery lists them with the reflog (`advanced.rs:798-814`).
  - Force push is `--force-with-lease=refs/heads/<b>:<lease>` only (`advanced.rs:288-298`); plain Push never forces (test `operations.rs:508`).
  - Reset hard, discard, drop stash, delete branch/remote/worktree all go through confirmation dialogs with consequences spelled out (`ui/advanced.rs:24,60,105,137,424`; `ui/workflow.rs:91,560-576`; `ui/repository_actions.rs:117,193`; `ui/remotes.rs:74`; `ui/worktree_manager.rs:78-179`).
  - Discard warns "Discarded changes can't be recovered" (`ui/workflow.rs:91`); worktree removal never forces (`core/worktrees.rs:1`).
- Credentials: Git runs with `GIT_TERMINAL_PROMPT=0` (`core/operations.rs:483`, `control.rs:238`); no askpass is provided. Hosting tokens (reviews, PRs) go to `secret-tool` (`providers/credentials.rs:27`) and aren't used for Git transport (README:219). Credential-bearing remote URLs are hidden (README:117).
- Persistence: drafts survive restarts (README:101); prefs via nyx-core.

## UX and accessibility (static)

- Ctrl+Enter commits; 10 shortcut sites; command palette (`ui/palette.rs`).
- Colours: `style.css:667` `#ffffff` on a coloured chip; graph colours from the theme.

## Reliability

- Per-repository flock serialises Git children (package comment).
- Long operations run in background workers with output caps (`core/jobs.rs:137`).

## Integration and packaging

- Desktop entry `apps/git/data/io.github.design_nexus.nyx.Git.desktop` (`Exec=nyx-git %f`; no MIME, no `StartupWMClass`).
- Glimpse panel `nyx-glimpse/quickshell/Glimpse/panels/git`.
- Omarchy: "Open in editor" tries `omarchy-launch-editor` only if present (`ui/workspace.rs:141-142`), otherwise `$VISUAL/$EDITOR`; the error text still says "or use Omarchy defaults" (`workspace.rs:152`).

## Maintenance

- Tests: 63 (serial in the Nix build); CI `check.yml`, `release.yml`.
- Pins: nyx-core `9187295` (= origin/main), nyx-design `8b41fb1`.

## Runtime results

- Smoke test (Git): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 22 / 608 ms (two warm runs), RSS 174 MB 4 s after start (logs/perf-app-startup.txt, dev VM).

## Findings

### NYX-APP-GIT-001: Push/fetch over authenticated HTTPS or passphrase SSH needs setup NyxOS doesn't provide

- **Component:** nyx-git `apps/git/src/core/operations.rs:483`; nyxos (no credential helper, askpass or SSH agent configuration found under `modules/`)
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Nyx Git deliberately defers to native Git credential helpers, SSH agents and askpass and disables terminal prompts. A fresh NyxOS install configures none of these, so pushing to a private HTTPS remote, or using a passphrase-protected SSH key without an unlocked agent, fails with Git's "terminal prompts disabled"/"Permission denied" message. The hosting sign-in in the app doesn't help Git transport.
- **Expected:** Push works after signing in, or the app explains the one-time setup (e.g. `credential.helper` with libsecret, an SSH agent via GNOME Keyring/gcr).
- **Actual:** `GIT_TERMINAL_PROMPT=0`; no `SSH_ASKPASS`/`GIT_ASKPASS` set; `rg credential|askpass|ssh-agent nyxos/modules` finds nothing relevant.
- **Reproduce / verify:** Fresh NyxOS user: clone a private HTTPS repo and push (static; confirm at runtime, including whether gnome-keyring's SSH agent is active).
- **Evidence:** as cited; `README.md:103,117,219`
- **Affected versions:** `84deb0895a`
- **User impact:** The main publish workflow fails until the user configures Git by hand.
- **Recommended correction:** Ship `git-credential-libsecret` as the default helper on NyxOS and an askpass (e.g. a small GTK askpass or `ksshaskpass`-style helper), or let the app feed its hosting token to Git through a credential helper.
- **Effort:** M
- **Dependencies:** NYX-SYS (session agents)
- **Verification criteria:** Fresh user can push to GitHub over HTTPS after signing in, with no terminal.

### NYX-APP-GIT-002: Omarchy wording in an editor error message

- **Component:** nyx-git `apps/git/src/ui/workspace.rs:152`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** With no editor configured, the error says "Set {variable} or use Omarchy defaults." The `omarchy-launch-editor` call itself is presence-gated and harmless.
- **Expected:** NyxOS wording (Settings → Default apps, or `$EDITOR`).
- **Actual:** as cited.
- **Reproduce / verify:** Unset `VISUAL`/`EDITOR`, choose Open in editor.
- **Evidence:** `workspace.rs:141-152`
- **Affected versions:** `84deb0895a`
- **User impact:** Confusing message.
- **Recommended correction:** Reword; fall back to `xdg-open` on the folder or the default text editor.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No "Omarchy" in user-visible strings.
