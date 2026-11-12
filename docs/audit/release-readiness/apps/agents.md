# Nyx Agents scorecard

- **Repository:** design-nexus/nyx-agents at `e2ad8b0801` (pinned in nyx-packages: yes, 0 behind origin)
- **Release tier:** not offered (packaged; enabled only on the dev VM; no catalog item)
- **Purpose:** native workspace for AI coding agents (Claude Code, Codex, oh-my-pi, Muse, Grok Build, Antigravity, Crush, Cursor CLI, OpenCode, Hermes) in a libghostty-vt terminal, with a session manager, subagent inspector, optional headless agent desktops and the AI Hub bar/Control Center plugin
- **Stack:** Rust/GTK4 (23k lines), libghostty-vt (Zig), SQLite; Unix socket `%t/nyx-agents/agents.sock` (0600)
- **Binaries / services:** `nyx-agentd` (socket-activated, `KillMode=process`), `nyx-agents` (app and CLI), `agents-glimpse` (Glimpse plugin), `nyx-ai-hub-plugin` in `share/nyx/plugins/nyx.ai-hub`; runtime sway, dbus, Xwayland, foot, git (`nyx-packages/pkgs/nyx-agents.nix`; module `default.nix:659-675`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Phases 0-2 and 4 done; Phase 3 partial (all ten launch, two resume, five report status; README) |
| UX | 2 | Sessions sidebar, tabs, splits, deep links, notifications; terminal UX unverified |
| Accessibility | 1 | Custom terminal widget has no accessible text model; 13 tooltips, 3 accessible properties |
| Reliability | 2 | Holders outlive the manager; 194 unwrap/expect, mostly mutex locks and serialisation |
| Integration | 2 | Socket activation, Glimpse, AI Hub, notifications; Settings page installed where Settings doesn't look |
| Packaging | 2 | Clean module; libghostty-vt built in nyx-packages; dev-only |
| Maintainability | 2 | 90 tests, good docs; no CI workflow |

## Functionality

- **What it runs:** whatever harness binaries the user has on PATH, each under a holder process in its own session (`data/nyx-agentd.service`: `KillMode=process`). Optional per-session git worktree (`--worktree`).
- **Permissions given to agents:** none added. No `--dangerously-skip-permissions`, `--yolo` or similar flags in the harness adapters (grep of `crates/nyx-agents-core`, `apps/nyx-agentd`). Agents run as the user with the user's files; their own permission prompts apply.
- **Agent workspaces:** a headless sway per session with its own D-Bus; Claude Code, Codex and Muse get a `nyx-computer` MCP server on their command line; `nyx-agents computer register` writes the server into other harnesses' user configs on request (`docs/WORKSPACES.md:31-41`). Programs in a workspace run as the user.
- **Persistence:** session records in SQLite under the user's data dir; usage scanners read harness logs.

## UX and accessibility (static)

Glimpse search (`agents`, `agents needs`), notifications when an agent needs you, `--open session/ID`. Terminal palette uses the theme's background/foreground/accent and Omarchy's ANSI colours when present, else Catppuccin Mocha (`apps/nyx-agents/src/ui/theme.rs:88-111`). Terminal content isn't exposed to screen readers (custom `TerminalView`).

## Reliability

Restarting `nyx-agentd` keeps agents running and reattaches. Unwraps in `apps/nyx-agentd/src/server.rs` (66, 49 are `lock().unwrap()`, the rest `serde_json::to_value` of owned structs) are low risk.

## Integration and packaging

Desktop entry with `x-scheme-handler/nyx-agents` and icon (`data/`); Glimpse plugin (`glimpsePlugin = true`); AI Hub installed as a trusted packaged plugin; Settings extension installed to `$out/share/nyx-settings/extensions/agents` (`nyx-agents.nix:76`), which Settings never reads (NYX-APP-AGENTS-001). Omarchy: only the ANSI-colour fallback and a mockup tool.

## Maintenance

90 tests (terminal, protocol, core, plugin; package runs them). No `.github/workflows`. Pins nyx-core `4f05fb8` and `4378e24`, nyx-design `cf39397` and `40db521` (two revisions each), nyx-glimpse `6f9f732`. Docs: TERMINAL, WORKSPACES, HARNESSES, HUB, INSPECTOR, AUDIT.

## Runtime results

- Smoke test (Agents): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-AGENTS-001: Packaged Settings page is never loaded

- **Component:** `nyx-packages/pkgs/nyx-agents.nix:76`; nyx-settings `apps/settings/src/paths.rs:8-11`, `src/ext/mod.rs:206-207`
- **Category:** packaging
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Settings reads extensions only from `~/.local/share/nyx-settings/extensions`; the package installs the Agents page into the store, where nothing looks.
- **Expected:** Packaged apps' Settings pages appear on NyxOS (H09 Settings).
- **Actual:** No system data dir in `ext_dir()`; same gap affects Clipboard (NYX-APP-CLIPBOARD-001).
- **Reproduce / verify:** Enable `nyx.agents` on the VM; open Settings and look for Agents. Static; confirm at runtime.
- **Evidence:** as above
- **Affected versions:** `e2ad8b0801`, nyx-settings `7e76622f35`
- **User impact:** Agents' settings unreachable from Settings.
- **Recommended correction:** Have Settings also read `share/nyx-settings/extensions` in `XDG_DATA_DIRS`.
- **Effort:** S
- **Dependencies:** NYX-APP-CLIPBOARD-001
- **Verification criteria:** Agents page visible in Settings on the VM.

### NYX-APP-AGENTS-002: No CI and an inaccessible terminal

- **Component:** nyx-agents (repository), `crates/nyx-term-gtk`
- **Category:** accessibility
- **Severity:** P3
- **Status of feature:** exploratory
- **Description:** No workflow runs the 90 tests on push; the terminal widget exposes no text to assistive technology.
- **Expected:** CI like other suite apps; GTK accessible text or role for terminal content.
- **Actual:** `.github/workflows` absent; no `AccessibleText` in `nyx-term-gtk`.
- **Reproduce / verify:** `ls .github`; Orca on a session tab.
- **Evidence:** as above
- **Affected versions:** `e2ad8b0801`
- **User impact:** Regressions slip in; screen-reader users can't follow agents. Not user-facing yet (dev VM only).
- **Recommended correction:** Add `check.yml`; implement accessible text for the terminal before offering the app.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** CI green on push; Orca reads terminal output.
