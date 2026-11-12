# Shared infrastructure

Static review (source, configuration, docs) of the shared services against handoffs 02,
04, 05, 06, 08, 09 and handoff 10 sections 9, 14, 15, 16 and 21. Nothing was built or
run. Revisions read: nyx-design `e311c2f`, nyx-system `6f0c47c`, nyx-ai `d325462`,
nyx-voice `1ebd749`, nyx-core `9187295`, nyx-settings `7e76622`, nyx-assistant `58ed80e`,
nyx-chat `38a8bae`, nyx-glimpse `deecabf`, nyx-packages `d69e87e`, nyxos `97f1573`.
Repository docs (nyx-ai `docs/*.md`, nyx-system `docs/updates.md`, nyx-design
`docs/theme-engine/*.md`, `nyx/docs/desktop/CONNECT.md`, nyx-settings
`docs/configuration.md`, nyxos `docs/audit/*`) were treated as claims and checked
against code; where they disagree, the finding says so.

Status values: **verified** here means verified by code reading only (static; confirm at
runtime). No runtime claim in this report has been measured.

## Scorecard

0 = absent or broken, 1 = weak, 2 = adequate with gaps, 3 = good. Basis: what the code
and packaging show, not the docs.

| Component | API stability | Security | Performance (static) | Failure isolation | Test coverage | Documentation |
| --- | --- | --- | --- | --- | --- | --- |
| Theme Engine 2.0 (nyx-theme-core, nyx-theme, nyx-themed, Nyx.Theme) | 1: versioned schema and `Theme1` D-Bus API, but apps compile the engine in at 7 revisions with different built-in palettes (NYX-THEME-001) | 2: themes are data only, links/executables/hooks refused, atomic swap; clone unbounded (NYX-THEME-004) | 2: inotify and signals, no polling, 250 ms debounce; `A11y::system()` spawns `dconf` twice per resolve | 3: clients resolve without the service, broken values fall back per token, QML has a built-in fallback | 2: core, installer (hostile repos) and D-Bus tests; GTK adapter untested in packaging | 2: thorough `docs/theme-engine`; nyxos README still says Nyx Dark |
| AI Core (nyx-aid, client, proto, llama-prism) | 3: `API_VERSION` handshake, explicit `incompatible_version`, typed errors | 1: Unix socket is uid-checked and program-trusted, but the OpenAI endpoint on 127.0.0.1:8080 is unauthenticated and on by default (NYX-AI-001) | 2: leases, aging priority queues, LRU eviction, idle unload, PSI pressure; benchmarks from one laptop only | 2: supervised worker with backoff and crash limit; but the TCP bind can take the whole socket unit down (NYX-AI-002) | 2: 62 tests incl. daemon vs stub worker, run in nyx-packages; no repo CI | 2: good ARCHITECTURE/PROTOCOL; ASSISTANT.md overstates action use |
| Nyx Voice (nyx-voiced, nyx-voice-engine) | 2: separate proto crate, socket protocol documented | 1: peer uid and trusted-program checks for the mic, but models fetched unverified (NYX-VOICE-002) | 2: socket-activated, engines unloaded when idle | 2: independent daemon; Assistant links the engine in-process (documented) | 1: 22 tests, ASR end-to-end ignored, no CI | 1: VOXTYPE.md claims NyxOS key bindings that don't exist (NYX-VOICE-001) |
| Nyx Connect (fluxd 0.19.1 + patch, nyx-connect, nyx-devices) | 2: thin client over fluxd's documented JSON-lines IPC, pinned release | 2: `shareHome` off by default, socket 0600; port 12100 open on every network (NYX-CONN-001) | 2: `subscribe`, no polling, reconnect backoff to 30 s | 3: no Nyx daemon; consumers get `Unavailable` and keep working | 2: 315-line test module in nyx-connect | 3: CONNECT.md capability matrix matches code |
| System Manager, recovery, `nyx update` | 2: D-Bus `System1`, JSON payloads, documented exit codes | 2: polkit per action, root-only bus name; recovery is passwordless root (NYX-SYS-001) | 2: 3 GB free-space gate, idle I/O class for the daily run | 3: lock and tool pins restored on failure, interrupted-update marker, previous generation on failed switch | 2: 87 tests; no repo CI | 2: updates.md accurate except plan detail (NYX-UPD-001) |
| Settings, config layers, capabilities | 2: `nyx-config` layered domains with schema migration; no Settings IPC (NYX-SET-002) | 2: system changes only via System Manager on NyxOS (root helper removed) | 2: capability providers event-driven; some pages poll every 4 s | 2: broken files set aside; theme.toml is the exception (NYX-THEME-003) | 3: 288 Settings tests, plus nyx-config, nyx-capability, nyx-devices tests | 2: configuration.md matches code; Omarchy strings leak (NYX-SET-001) |
| Shared action registry (nyx-actions, AI Core actions) | 2: control API 2, JSON Schema validation | 1: trust by executable is bypassed by the trusted `nyx-actions … --yes` CLI (NYX-AI-004) | 2 | 2 | 2: registry tests on a private bus | 2 |

## 1. Theme Engine 2.0

| Feature (handoff 02) | Status | Evidence |
| --- | --- | --- |
| Shared Rust library (schema, registry, resolver, config, installer, Omarchy import, contrast, snapshot) | verified | `nyx-design/crates/nyx-theme-core/src/lib.rs:5-28` |
| Theme service with generations and change signal | verified | `nyx-system/apps/themed/src/service.rs:72-123,137-237`; D-Bus `io.github.design_nexus.nyx.Theme1` (`nyx-theme-core/src/dbus.rs:12-15`), activated as `nyx-themed.service` (`nyx-packages/pkgs/nyx-system.nix:27-31`, `modules/nixos/default.nix:582-612`) |
| QML adapter | verified | `nyx-design/qml/Nyx/Theme/NyxTheme.qml:16-33,113,211-225` reads `$XDG_RUNTIME_DIR/nyx/theme/system.json` with `fallback.js` |
| GTK adapter, live reload | verified | `nyx-design/crates/nyx-theme/src/lib.rs:944-971` (`ThemeChanged` plus GIO file monitor, older generations ignored) |
| Semantic tokens | verified | `nyx-theme-core/src/tokens.rs`; `builtin-themes.json` |
| Catppuccin Mocha is the default | verified (palette deviates, see NYX-THEME-002) | `config.rs:16`; `nyxos/modules/nixos/overrides.nix:66-70,219-222`; `apps.nix:68,101-106` |
| Follow System default, per-app overrides | verified | `config.rs:28-37,191-219`; `lib.rs:108-122`; resolver keeps a missing override and follows the system (`resolver.rs:126-133`) |
| Shell components always follow the system | verified | `config.rs:103-105` (`Scope::Shell`) |
| GitHub install, update, rollback, removal | verified | `installer.rs:59-96,454-475,499-640`; built-ins not removable (`installer.rs:614-623`) |
| Installation safety | partial | data-only copy, links/executables/hooks refused, size caps (`installer.rs:22-26,222-270`), git transports restricted (`nyx-core/crates/nyx-core/src/fetch.rs:18-68`); full clone with no size or time cap (NYX-THEME-004) |
| Omarchy `colors.toml` import | verified | `installer.rs:643`, `omarchy.rs` |
| Fallback on broken theme | verified | `resolver.rs:1-10,146-156`; selection refuses themes with errors (`lib.rs:80-89`) |
| Accessibility (contrast warnings, reduced motion, high contrast) | partial | `contrast.rs`; dconf reading only from `53bf2d7` on; most apps still use `gsettings`, absent on NyxOS (NYX-THEME-001); default theme fails AA for secondary text (NYX-THEME-002) |
| One theme across the desktop | partial | 7 nyx-design revisions compiled into apps (NYX-THEME-001) |
| Omarchy leftovers | present, mostly harmless | `Suite::default()` mode `Omarchy` (`config.rs:84`, falls back off Omarchy); nyx-packages `nyx.wallpapers.theme` default `nyx-dark` (`modules/nixos/default.nix:240-243`, overridden by nyxos `apps.nix:68`); boot menu falls back to the nyx-dark lock image (`nyxos/modules/nixos/boot.nix:22-23`) |

## 2. AI Core

| Feature (handoff 04, handoff 10 §14) | Status | Evidence |
| --- | --- | --- |
| Single llama.cpp runtime (Prism fork, Vulkan/CPU/CUDA) | verified | `nyx-packages/pkgs/llama-prism.nix` (pinned rev and hash), `nyx-ai.nix`, module `ai.acceleration` (`modules/nixos/default.nix:63-75,185-196`) |
| Model registry and states | verified | `nyx-ai-core/src/registry.rs`; states in ARCHITECTURE.md:78-82 match |
| Downloads: HF only, `.gguf` only, LFS SHA-256, resume, disk-space check, cancel | verified | `downloads.rs:83,102-121,219-237,316-321` |
| Leases, idle unload (900 s default), max loaded, eviction, memory pressure | verified | `scheduler.rs:19,121,214-228,363-385,524-546`; `config.rs:40-41` |
| Priority classes and aging | verified | `scheduler.rs:5,19,68-75` |
| Streaming and cancellation | verified | `stream.rs`; per-connection request tables (`server.rs`); OpenAI path cancels on disconnect (`openai.rs:60-85`) |
| Worker supervision | verified | `worker.rs:22,397,406,427,475-488` (process group, PDEATHSIG, API key file, backoff, crash limit) |
| Client isolation and peer checks | verified | `server.rs:131-134,169-178`; privileged ops limited to trusted programs (`service.rs:194,310`) |
| Embeddings and Glimpse index identity | implemented, not verified | `nyx-glimpse/apps/glimpse/src/aicore.rs:30` (`LEGACY_IDENTITY`); `glimpse-embed` runtime link removed (`modules/nixos/default.nix:416-421`) |
| IPC security | partial | Unix socket good; OpenAI endpoint unauthenticated (NYX-AI-001) and bound in the socket unit (NYX-AI-002) |
| Shared action registry in AI Core | partial | `actions.rs:119-131`; Assistant doesn't use it (NYX-AI-003); CLI bypass (NYX-AI-004) |

Who uses AI Core: Chat (`nyx-chat/apps/chat/src/llama/core.rs:166`, downloads too; Ollama
kept as an external provider), Glimpse (`aicore.rs:207,213`), Assistant
(`assistant-inference/src/lib.rs:13-24`; `llama-cpp-2` is gone from its `Cargo.lock`),
Notes (`notes-ai/src/provider.rs`). No app still links llama.cpp. Remaining private speech
stacks are in NYX-VOICE-003.

## 3. Chat, Glimpse 2.0, Assistant 2.0, Aura, action registry (handoff 05)

| Item | Status | Evidence |
| --- | --- | --- |
| Chat on AI Core, runner removed | verified | see above; no `llama-server` unit in nyx-chat |
| Glimpse embeddings via AI Core, actions via registry | implemented, not verified | `aicore.rs`, `commands.rs:332`, nyx-actions dependency (`apps/glimpse/Cargo.toml:16`) |
| Glimpse direct search independent of AI Core | implemented, not verified | AI Core calls have 3 s timeouts (`aicore.rs:207`); confirm with nyx-aid stopped |
| Assistant inference on AI Core | verified | `assistant-inference/src/lib.rs:13-24` |
| Assistant speech via Nyx Voice | partial | links `nyx-voice-engine` in-process (`apps/assistant/Cargo.toml:41-42`, `assistant-agent/src/asr.rs:1-2`), not `nyx-voiced`; documented latency exception (nyx-voice README) |
| Assistant on the shared action registry | approved, not implemented | NYX-AI-003 |
| Aura (Full, Edge Flow, reduced motion, theme) | partial | GTK4 layer-shell (`assistant-visual/src/main.rs:1-5,217,280,378`), not the Quickshell/Shell Core presentation handoff 05 §8 approves |

## 4. Nyx Voice

| Feature | Status | Evidence |
| --- | --- | --- |
| Dictation service (type or clipboard, pause media, 60 s cap, state file) | implemented, not verified | nyx-voice README; `apps/nyx-voiced/src/voice.rs` |
| Local STT (sherpa-onnx Nemotron streaming, English only) and TTS (Kokoro) | implemented, not verified | `nyx-voice-proto/src/asr.rs:28`, `nyx-voice-engine/src/tts.rs` |
| Microphone permission, same-user peers | verified | `apps/nyx-voiced/src/server.rs:1,35-46,135-145` |
| Device handling | implemented, not verified | `nyx-voice-engine/src/duck.rs`, `nyx-voice devices` |
| Independent of Assistant | partial | service is independent, but `nyx.voice.enable` defaults to `nyx.assistant.enable` (`nyx-packages/modules/nixos/default.nix:164-172`) and nothing binds dictation keys (NYX-VOICE-001) |
| VoxType removed on NyxOS | verified | no `voxtype` in nyxos modules; Settings shows Nyx Voice on NyxOS (`nyx-settings/.../capture.rs:305-309`) |
| Verified model downloads | not implemented | NYX-VOICE-002 |

## 5. Nyx Connect

| Feature (handoff 06) | Status | Evidence |
| --- | --- | --- |
| Upstream fluxd, pinned | verified | `nyx-packages/pkgs/flux.nix` (0.19.1, CLI and daemon only) |
| Patch scope (not a fork) | verified | `flux-nyxos.patch`: Do Not Disturb through nyx-notifyd's `Notifications1` and the theme read from nyx-themed's snapshot; nothing else. Minimal, documented, tested (`theme_nyx_test.go`) |
| Thin integration layer, no second device database | verified | `nyx-core/crates/nyx-connect/src/lib.rs:1-19`; trust stays in fluxd |
| Remembered devices, forget vs unpair | verified | `nyx-connect/src/lib.rs:38-60`; `nyx-devices/src/lib.rs:248-303` |
| Consumers | verified | Settings, Control Center, Clipboard, Share, Notification Center link nyx-connect; Glimpse and Assistant don't |
| Failure when fluxd is down | implemented, not verified | `watch.rs:26,48-69` (reconnect, `Unavailable`), client timeouts 5 to 10 s (`client.rs:125-142,203`) |
| Safe defaults | partial | `share_home = false`, `check_updates = false` for new users (`nyxos/modules/nixos/apps.nix:90-95`); port 12100 open everywhere (NYX-CONN-001) |

## 6. System Manager and updates

| Feature (handoff 08, handoff 10 §21) | Status | Evidence |
| --- | --- | --- |
| `nyx update` with categories and individual targets | verified | `nyxos/pkgs/nyx-cli/nyx.sh:241-244` → `nyx-system update`; categories `nyx-update/src/lib.rs:28-50`; aliases (`claude`, `cursor`, `cursor-agent`, `grok`, `agy`) in `nyxos/pkgs/tools/sources.json` |
| Plan, `--dry-run`, confirmation, `--json` | partial | NYX-UPD-001 |
| Build before switch, restore on failure, interrupted-update recovery, 3 GB gate | verified | `nyx-system/apps/system-manager/src/upgrade.rs:20-75,233-313` |
| Generations and rollback (incl. lock and pins) | verified | `rebuild.rs:103-176`; recorded in history (`upgrade.rs:342-350`) |
| History and report | verified | `upgrade.rs:32-34,186-220`; user history per docs |
| Firmware via fwupd, never unattended, unsupported state reported | verified | `nyx-update/src/run.rs:345`, `probe.rs:424-434`, `policy.rs:125-129`; fwupd on for physical machines (`nyxos/modules/nixos/hardware.nix:94`) |
| Restart and reboot reporting | verified | `upgrade.rs:128-162` |
| Tool pins and CI (propose without secrets, publish PRs, no auto-merge by default) | verified | `nyxos/.github/workflows/tool-updates.yml:1-60`, `scripts/update-tool`, docs/updates.md:139-168 |
| Stable channel / known-good tags | verified, process manual | `templates/host/flake.nix:6` follows `stable`; `origin/stable` = `known-good/22`; promotion is a tag plus VM snapshot (`docs/dev-vm.md:140-143`); NYX-UPD-002 |
| Recovery console | verified | `nyxos/modules/nixos/recovery.nix`; NYX-SYS-001 |
| Polkit per System Manager method | verified | `system-manager/src/main.rs:97-160,342-576`; `data/io.github.nyxos_project.system.policy` |

## 7. Settings and defaults

| Feature (handoff 09, handoff 10 §16) | Status | Evidence |
| --- | --- | --- |
| Three configuration layers | verified | `nyx-system/crates/nyx-config/src/lib.rs:1-80`; `/etc/nyxos/defaults` from `nyxos/modules/nixos/overrides.nix:218-237` |
| Write only what differs; schema migration with backup; broken files set aside | verified | `nyx-config/src/store.rs:6-7,153-217,278` |
| Reset (key, page, all) | verified | `store.rs:202-210`; Settings rows (`widgets.rs:692`, `desktop.rs:33`, `about.rs:169-183`) |
| Capability-aware controls and dynamic navigation | verified | `nyx-settings/apps/settings/src/capability.rs`; `nyx-core/crates/nyx-capability` |
| Remembered devices, offline editing | verified | `nyx-devices`; configuration.md:126-155 matches code |
| No hardware-specific global defaults | verified | `nyxos/defaults/*.toml` hold no monitor names, scales or layouts; monitor rule is generic (`modules/home/hyprland.nix:86`), keyboard layout from the host (`:44`); Ken's user only in `hosts/incus-dev` |
| One store per setting | partial | Hyprland settings live in Settings' `state.json`, not the `hyprland` domain; the administrator layer doesn't reach Hyprland (NYX-SET-002) |
| Settings IPC (get/set/reset/subscribe) | approved, not implemented | NYX-SET-002 |
| Omarchy dependencies on NyxOS | mostly gated | 82 `PLATFORM`/feature gates; Omarchy programs are `program:omarchy-*` capabilities, hidden when absent (`capability.rs:41-58`); root helper removed on NyxOS (`nyx-packages/pkgs/nyx-settings.nix:33-35`); residual strings (NYX-SET-001) |

## 8. Shared IPC and permissions

| Endpoint | Owner | Bus or path | Access control |
| --- | --- | --- | --- |
| `io.github.nyxos_project.System` | nyx-system-manager (root, D-Bus activated) | system bus | only root may own; anyone may call; each mutating method asks polkit (`auth_admin_keep`, `auth_admin` for groups/apply, `auth_self` for own password) |
| `io.github.design_nexus.nyx.Theme` (`Theme1`) | nyx-themed | session bus | none beyond the session bus; any session client can install a theme from a URL |
| `$XDG_RUNTIME_DIR/nyx/theme/system.json` | nyx-themed (sole writer from `553f655`) | file | user-owned runtime dir; older app pins may also write |
| `$XDG_RUNTIME_DIR/nyx-ai/ai.sock` | nyx-aid | Unix socket, 0600 in 0700 dir | `SO_PEERCRED` same uid; trusted program via `nyx-peer` for privileged ops |
| `127.0.0.1:8080` | nyx-aid (socket unit) | TCP | loopback only; **no authentication**, no Host/Origin check |
| `$XDG_RUNTIME_DIR/nyx-ai/worker.sock` | llama-server | Unix socket | per-start API key file |
| `$XDG_RUNTIME_DIR/nyx-voice/voice.sock` | nyx-voiced | Unix socket, 0600 | same uid; microphone and typing for trusted programs or a config allow-list |
| `$XDG_RUNTIME_DIR/flux/fluxd.sock` | fluxd | Unix socket, 0600 | same uid (fluxd checks `SO_PEERCRED`) |
| TCP/UDP 12100, mDNS `_flux._udp` | fluxd | network | TLS with certificates pinned at pairing; port open in the firewall on all interfaces |
| `io.github.design_nexus.nyx.Notifications` (`Notifications1`) | nyx-notifyd | session bus | none beyond the session bus (fluxd calls `Dnd`/`SetDnd`) |
| `io.github.design_nexus.nyx.Control` per app | each Nyx app | session bus | caller identified by PID → executable (`nyx-actions/src/server.rs:160-197`); non-read-only actions need a trusted program; `confirmed` supplied by the caller |
| `$XDG_RUNTIME_DIR/nyx-shell/core.sock` | Shell Core | Unix socket | see the shell report |

## Findings

### NYX-THEME-001: Apps build seven different copies of the theme engine, so the default theme looks different in apps and the shell

- **Component:** nyx-design `crates/nyx-theme-core`, `crates/nyx-theme`; every app's `Cargo.toml` pin
- **Category:** architecture
- **Severity:** P2
- **Status of feature:** partial
- **Description:** The engine (including the built-in themes and the accessibility reader) is compiled into each app. Apps pin nyx-design at 7 revisions. Changes from 11 November that alter what users see never reached 35 apps on `cf39397` or the 5 components on `40db521`.
- **Expected:** One canonical theme definition for shell, GTK apps and Quickshell (handoff 02 §2.1, §2.10); reduced motion and high contrast honoured (§14).
- **Actual:** `cf39397..e311c2f` contains `99cb9df`/`7a9bd08` (built-in themes rebuilt from Omarchy's colours), `53bf2d7` (reduce-motion/high-contrast read with `dconf`; before it, `gsettings`, absent on NyxOS, so both always read off) and `553f655` (only nyx-themed writes the snapshot). Resolved Catppuccin Mocha at `40db521`/`cf39397`: `surface.secondary #181825`, `text.secondary #a6adc8`; at `e311c2f` (nyx-themed at `53bf2d7`, Settings at `997a2c1`, shell at `553f655`): `#222333`, `#6c7086` (`builtin-themes.json`). `40db521` (nyx-shell, nyx-agents, nyx-installer, nyx-welcome, nyx-browser) also predates `78a1910`, so it ignores the administrator's and NyxOS's default theme in `/etc/nyxos/*/appearance.toml`. Apps on `cf39397` still publish the snapshot when they change the suite (`nyx-theme/src/lib.rs:613-620` at `cf39397`), racing nyx-themed.
- **Reproduce / verify:** `jq '.tokens.colors["surface.secondary"]' $XDG_RUNTIME_DIR/nyx/theme/system.json` versus the sidebar colour of Nyx Calculator; `NYX_REDUCE_MOTION` unset, `dconf write /org/gnome/desktop/interface/enable-animations false`, check an app's transitions. Static; confirm at runtime.
- **Evidence:** `evidence/shared-crate-pins.txt`; `git -C nyx-design log cf39397..e311c2f -- crates/nyx-theme-core crates/nyx-theme`; `nyx-design/crates/nyx-theme-core/src/lib.rs:167-182` vs `cf39397:…/lib.rs:173`
- **Affected versions:** nyx-design `cf39397`, `40db521` and every app pinning them; nyx-packages `d69e87e`
- **User impact:** Default desktop shows two shades of Mocha; accessibility settings ignored by most apps; a configured system theme ignored by Welcome and the installer.
- **Recommended correction:** Re-pin every app to one nyx-design revision per release (a nyx-packages check that fails on more than one); or have GTK apps take resolved tokens from nyx-themed's snapshot instead of resolving built-ins themselves.
- **Effort:** M
- **Dependencies:** NYX-PKG-002
- **Verification criteria:** One nyx-design revision across `Cargo.lock`s; snapshot and app colours identical; reduce motion toggles apps.

### NYX-THEME-002: The default Catppuccin Mocha isn't Catppuccin's palette and its secondary text fails WCAG AA

- **Component:** nyx-design `crates/nyx-theme-core/themes/catppuccin-mocha/colors.toml`
- **Category:** accessibility
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Since `99cb9df` Mocha is built from Omarchy's `colors.toml`, which adds non-Catppuccin colours, and the mapping puts `overlay0` on secondary text.
- **Expected:** "Use the established Catppuccin Mocha palette values … Do not invent an approximately similar palette" (handoff 02 §2.3); validated contrast (§14).
- **Actual:** `colors.toml:9-10,15-25` (`dark_background #161622`, `darker_background #101019`, `orange #f6b6ab`, `brown #7b5b55`); resolved `surface.secondary #222333`, `surface.tertiary #282839`, `text.secondary #6c7086` (3.36:1 on `#1e1e2e`, 2.96:1 on `#282839`), `text.tertiary #5c6074` (2.64:1).
- **Reproduce / verify:** `nyx-theme` resolve of `catppuccin-mocha`; compute contrast. Static.
- **Evidence:** `builtin-themes.json` (`catppuccin-mocha`); contrast computed from those values.
- **Affected versions:** nyx-design `99cb9df`..`e311c2f`
- **User impact:** Hard-to-read secondary labels everywhere on the default desktop.
- **Recommended correction:** Map Catppuccin roles explicitly (mantle/crust/surface0-2, subtext0/1 for secondary text); keep Omarchy fidelity for imported Omarchy themes only; make the contrast check fail the build for built-ins.
- **Effort:** S
- **Dependencies:** NYX-THEME-001
- **Verification criteria:** Mocha tokens equal official values; `text.secondary` ≥ 4.5:1 on primary and secondary surfaces.

### NYX-THEME-003: A corrupt theme.toml is silently replaced, losing overrides and token choices

- **Component:** nyx-design `crates/nyx-theme-core/src/config.rs`
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** partial
- **Description:** A `theme.toml` that fails to parse reads as "no file"; the next change writes defaults over it without a backup.
- **Expected:** No silent deletion of user preferences (handoff 10 §16); configuration corruption handled (handoff 09 §27), as `nyx-config` does (`store.rs:278`).
- **Actual:** `read_suite` returns `None` on any parse error (`config.rs:136-145,150`); `update_suite` starts from defaults and writes (`config.rs:181-188`).
- **Reproduce / verify:** Put `text_scale = "x"` in `~/.config/nyx/theme.toml` with an app override, change theme in Settings, inspect the file.
- **Evidence:** as above
- **Affected versions:** nyx-design `e311c2f` and earlier
- **User impact:** Per-app themes and custom tokens vanish after a hand edit mistake.
- **Recommended correction:** Keep the broken file as `theme.toml.broken-<time>` and notify, as nyx-config does; parse field by field.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Broken file preserved; overrides recoverable.

### NYX-THEME-004: Theme installation clones whole repositories with no size or time limit

- **Component:** nyx-core `crates/nyx-core/src/fetch.rs`; nyx-design `installer.rs`; nyx-themed `InstallTheme`
- **Category:** security
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Size limits apply only when copying data out of the checkout; the clone itself is a full-history `git clone` without depth, timeout or size cap, triggered by any session-bus client through `InstallTheme`.
- **Expected:** "Limit excessive asset sizes … download into a staging location" (handoff 02 §11.4).
- **Actual:** `fetch.rs:72-75` (`git clone --quiet -- URL`); limits at `installer.rs:22-26,257-268`; D-Bus method `service.rs:194-198` without caller checks.
- **Reproduce / verify:** `busctl --user call io.github.design_nexus.nyx.Theme /io/github/design_nexus/nyx/Theme io.github.design_nexus.nyx.Theme1 InstallTheme s https://github.com/<large-repo>`; watch `~/.local/share/nyx/themes/.staging`.
- **Evidence:** as above
- **Affected versions:** nyx-core `9187295`, nyx-design `e311c2f`
- **User impact:** A hostile or huge repository can fill the home disk or hang the theme service's worker thread.
- **Recommended correction:** `--depth 1 --filter=blob:limit=…`, `GIT_HTTP_LOW_SPEED_*` timeouts, a staging quota; consider limiting `InstallTheme` to Settings and the CLI.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Clone of a >100 MB repo aborts with a clear error; staging cleaned.

### NYX-THEME-005: Stale Nyx Dark and Omarchy defaults remain beside the Mocha default

- **Component:** nyx-packages `modules/nixos/default.nix`; nyxos `README.md`, `modules/nixos/boot.nix`, `iso/boot-menu.nix`; nyx-design `config.rs`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The NyxOS default is Catppuccin Mocha, but other defaults still name Nyx Dark or Omarchy.
- **Expected:** Catppuccin Mocha as the one default (handoff 02 §2.3, handoff 09 §20).
- **Actual:** `nyx.wallpapers.theme` default `"nyx-dark"` (`nyx-packages/modules/nixos/default.nix:240-243`; nyxos overrides it at `apps.nix:68`); lock-image fallback `nyx-dark` (`nyxos/modules/nixos/boot.nix:22-23`, `iso/boot-menu.nix:22`); README row "Theme tokens (Nyx Dark)" (`nyxos/README.md:30`); `Suite::default()` mode `Omarchy` (`config.rs:84`).
- **Reproduce / verify:** read the lines above.
- **Evidence:** as above
- **Affected versions:** nyx-packages `d69e87e`, nyxos `97f1573`
- **User impact:** Hosts using nyx-packages without nyxos get the old wallpaper; misleading docs.
- **Recommended correction:** Default to `catppuccin-mocha` everywhere; default `ThemeMode::Theme` off Omarchy.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `rg nyx-dark` finds only the theme itself.

### NYX-AI-001: The OpenAI-compatible endpoint on 127.0.0.1:8080 is unauthenticated and on by default

- **Component:** nyx-ai `data/nyx-aid.socket`, `crates/nyx-ai-core/src/openai.rs`
- **Category:** security
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Every install enables AI Core (`nyxos/modules/nixos/apps.nix:79`) and its socket unit listens on loopback TCP 8080. Any local account, and any web page through the browser, can send requests; nothing checks a key, `Host` or `Origin`, and the body is parsed as JSON whatever its content type.
- **Expected:** "Restrict access to authorized local clients. Validate peer identity" (handoff 04 §18); local-first privacy.
- **Actual:** `nyx-aid.socket:7` (`ListenStream=127.0.0.1:8080`; `SocketMode=0600` doesn't apply to TCP); `openai.rs:46-58` routes `POST /v1/*` without headers checks; `openai.rs:118` only checks loopback; ARCHITECTURE.md:61 "it has no key: any local program can use it".
- **Reproduce / verify:** As a second user: `curl -s 127.0.0.1:8080/v1/models`; from a browser page: `fetch('http://127.0.0.1:8080/v1/chat/completions',{method:'POST',mode:'no-cors',body:JSON.stringify({model:'…',messages:[…]})})`, then `nyx-ai status`.
- **Evidence:** as above
- **Affected versions:** nyx-ai `d325462`, nyx-packages `d69e87e`
- **User impact:** Other users and websites can load models, consume GPU/RAM and run inference as the owner; DNS rebinding could read replies.
- **Recommended correction:** Off by default (enable in Settings for coding tools), or a per-user token file plus `Host` allow-list and `Content-Type: application/json` requirement; per-user port.
- **Effort:** S
- **Dependencies:** NYX-AI-002
- **Verification criteria:** Requests without the token or with a foreign `Host` get 401/403; endpoint absent by default.

### NYX-AI-002: The AI Core socket unit fails for everyone when port 8080 is taken

- **Component:** nyx-ai `data/nyx-aid.socket`; nyx-packages `modules/nixos/default.nix:638-656`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** The Unix socket and the TCP port are in one socket unit, started per user. If 8080 is in use (a second logged-in user's nyx-aid, or a developer's server), systemd can't bind it and the whole unit fails, so the Unix socket the apps use is never created. Turning `openai_endpoint` off in settings.toml doesn't change the unit.
- **Expected:** Failures isolated; Chat, Assistant and Glimpse keep AI Core (handoff 04 §21, handoff 05 §12).
- **Actual:** `nyx-aid.socket:5-7`; the daemon copes without TCP (`apps/nyx-aid/src/main.rs:56-63`) but never starts if the socket unit failed.
- **Reproduce / verify:** Log in a second user (or `python3 -m http.server 8080` before login); `systemctl --user status nyx-aid.socket`; `nyx-ai status`. Static; confirm at runtime.
- **Evidence:** as above
- **Affected versions:** nyx-ai `d325462`
- **User impact:** Local AI and semantic search silently unavailable for the second user or for developers using 8080.
- **Recommended correction:** Separate `nyx-aid-openai.socket` (optional, off by default) or let the daemon bind TCP itself after start.
- **Effort:** S
- **Dependencies:** NYX-AI-001
- **Verification criteria:** With 8080 busy, `ai.sock` exists and `nyx-ai status` answers.

### NYX-AI-003: Nyx Assistant doesn't use the shared action registry

- **Component:** nyx-assistant `apps/assistant/crates/assistant-tools`
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** approved, not implemented
- **Description:** Glimpse discovers and invokes app actions through nyx-actions and AI Core; the Assistant keeps its own MCP-style registry and never calls `list_actions`/`invoke_action`, so the two enforce different rules.
- **Expected:** "Glimpse and Assistant must use the same action contract … enforce the same underlying authorization rules" (handoff 05 §9, handoff 04 §15).
- **Actual:** `assistant-tools/src/lib.rs:1-2`, `discovery.rs`; no `nyx-actions` dependency and no `invoke_action` in nyx-assistant; Glimpse uses both (`aicore.rs:207,213`, `commands.rs:332`); nyx-ai `docs/ASSISTANT.md:62` says the registry "can take app actions from AI Core".
- **Reproduce / verify:** `rg -n 'invoke_action|nyx_actions' nyx-assistant` (no hits).
- **Evidence:** as above
- **Affected versions:** nyx-assistant `58ed80e`
- **User impact:** An action allowed or refused in Glimpse may behave differently in the Assistant; app actions added for Glimpse don't reach the Assistant.
- **Recommended correction:** Feed `list_actions_detail` into the Assistant's tool catalog and route app actions through `invoke_action`, keeping assistant-policy as the extra gate.
- **Effort:** M
- **Dependencies:** NYX-AI-004
- **Verification criteria:** The Assistant lists and runs `calendar.*` actions through AI Core with the same confirmation prompts as Glimpse.

### NYX-AI-004: Any program can run confirmed, trusted app actions through the `nyx-actions` CLI

- **Component:** nyx-core `crates/nyx-actions/src/bin/nyx-actions.rs`, `server.rs`; nyx-packages `/etc/nyx/trusted-bin`
- **Category:** security
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Apps trust callers by executable (`nyx-peer`), and `nyx-actions` is in `/etc/nyx/trusted-bin` (`nyx-packages/modules/nixos/default.nix:265-268`). The CLI always sends `trusted: true` and sets `confirmed` from `--yes` without a terminal (`nyx-actions.rs:12-21,247-248,266-270`). Any same-user script therefore passes the "only Nyx programs past read-only" and "confirmation required" gates (`server.rs:3-4,193-197`), e.g. `calendar.delete`, `files` trash.
- **Expected:** Sensitive actions need permission checks; a tool call is a proposal, not authorization (handoff 04 §15, handoff 05 §9).
- **Actual:** as above.
- **Reproduce / verify:** From an untrusted script: `nyx-actions call calendar.delete '{"calendar":"…","uid":"…"}' --yes`.
- **Evidence:** as above
- **Affected versions:** nyx-core `9187295`
- **User impact:** The registry's trust boundary is advisory; malware or a coding agent can drive destructive app actions silently.
- **Recommended correction:** CLI as untrusted unless on a TTY with a real prompt (or polkit-style confirmation through the shell), or don't list it in trusted-bin; pass the original caller to apps.
- **Effort:** M
- **Dependencies:** NYX-SEC (trust model)
- **Verification criteria:** The command above is refused without an interactive confirmation.

### NYX-VOICE-001: Dictation isn't wired on NyxOS, though Settings and docs say it is

- **Component:** nyxos `modules/home/hyprland.nix`; nyx-packages `modules/nixos/default.nix:164-172`; nyx-settings `sections/capture.rs`; nyx-voice `docs/VOXTYPE.md`
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** partial
- **Description:** The F9 / Right Alt hold and Super+Ctrl+X bindings exist only on the unmerged `handoff-05` branch (nyxos `5bd37f5`, `nyxos-h05/modules/home/hyprland.nix:225,230`). On `main` nothing binds them, and Nyx Voice is off unless the Assistant is enabled.
- **Expected:** Replace VoxType preserving activation and insertion; "Nyx Voice must work independently of Assistant" (handoff 05 §6).
- **Actual:** No `nyx-voice dictate` binding in nyxos `main`; `voice.enable` default `cfg.assistant.enable`; Settings says "Hold F9 or Right Alt and speak, or press Super+Ctrl+X" (`capture.rs:383`); VOXTYPE.md:22-23 says NyxOS binds them.
- **Reproduce / verify:** On a base install press F9; `systemctl --user status nyx-voiced.socket`; `rg 'nyx-voice dictate' nyxos/modules`.
- **Evidence:** as above
- **Affected versions:** nyxos `97f1573`, nyx-packages `d69e87e`, nyx-settings `7e76622`
- **User impact:** Advertised dictation does nothing.
- **Recommended correction:** Merge the bindings from `5bd37f5`; default `nyx.voice.enable = true` (socket-activated, so cheap) or hide the Settings text when Nyx Voice is absent.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** F9 hold types speech on a fresh install without the Assistant.

### NYX-VOICE-002: Speech models are downloaded without integrity checks, one from a moving branch

- **Component:** nyx-voice `crates/nyx-voice-engine/src/asr.rs`, `silero.rs`; `crates/nyx-voice-proto`
- **Category:** security
- **Severity:** P2
- **Status of feature:** partial
- **Description:** The 650 MB ASR archive and the Silero VAD model are fetched with `curl` and used without a checksum; Silero comes from GitHub `master` (`raw/master/...`), which changes without notice.
- **Expected:** "Validate sources … validate model files before loading" (handoff 04 §18, applied to speech by handoff 05 §6 privacy and security).
- **Actual:** `asr.rs:327` (curl to `MODEL_URL`, `nyx-voice-proto/src/asr.rs:28`), then extracted; `silero.rs:211-219`; URL `nyx-voice-proto/src/settings.rs:112`. No `sha` anywhere in the repo.
- **Reproduce / verify:** `rg -i sha nyx-voice` (no hits); `nyx-voice models fetch asr` with a proxy that alters the file.
- **Evidence:** as above
- **Affected versions:** nyx-voice `1ebd749`
- **User impact:** A tampered or changed model is loaded into ONNX Runtime with microphone audio.
- **Recommended correction:** Pin URLs to tags/commits and verify SHA-256 before extraction; refuse archives with absolute or `..` paths.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A modified archive is refused.

### NYX-VOICE-003: Chat keeps its own speech stack instead of Nyx Voice

- **Component:** nyx-chat `apps/chat/src/voice.rs`
- **Category:** architecture
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Chat's dictation and read-aloud call whisper.cpp and Piper directly; users must install them and pick a model file by hand.
- **Expected:** Nyx Voice as reusable local speech for authorized Nyx apps (handoff 05 §6).
- **Actual:** `voice.rs:1,31-35,84-92`.
- **Reproduce / verify:** Chat › Settings › Voice on NyxOS: it asks for `whisper-cli`.
- **Evidence:** as above
- **Affected versions:** nyx-chat `38a8bae`
- **User impact:** Voice in Chat doesn't work out of the box; a third STT stack to maintain.
- **Recommended correction:** Use `nyx-voice-client` for listen/say.
- **Effort:** S
- **Dependencies:** NYX-VOICE-001
- **Verification criteria:** Chat dictation works with only Nyx Voice installed.

### NYX-CONN-001: Nyx Connect opens port 12100 and advertises the machine on every network by default

- **Component:** nyx-packages `modules/nixos/default.nix:362-381`; nyxos `modules/nixos/apps.nix:83`
- **Category:** security
- **Severity:** P2
- **Status of feature:** verified
- **Description:** `nyx.connect.enable` defaults on; it opens TCP and UDP 12100 on all interfaces and turns on Avahi publishing, whether or not a phone is paired and on any network (cafés, hotels).
- **Expected:** Permission handling and least exposure (handoff 06 §5.5, handoff 10 §15); firewall changes are a System Manager decision.
- **Actual:** `allowedTCPPorts = [ 12100 ]`, `allowedUDPPorts = [ 12100 ]`, `services.avahi.publish.userServices = true`; fluxd 0.19.1 is 18 commits behind upstream (inventory.md).
- **Reproduce / verify:** `sudo nft list ruleset | grep 12100`; `avahi-browse -a` from another machine on the LAN.
- **Evidence:** as above
- **Affected versions:** nyx-packages `d69e87e`
- **User impact:** A network-facing Go daemon and a discoverable hostname on untrusted networks.
- **Recommended correction:** Open the port only after the first pairing, or only on NetworkManager connections marked trusted; let Settings › Devices show and toggle it.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** A fresh install with no paired phone has 12100 closed.

### NYX-SYS-001: The recovery boot entry is a passwordless root console

- **Component:** nyxos `modules/nixos/recovery.nix`
- **Category:** security
- **Severity:** P2
- **Status of feature:** verified
- **Description:** Recovery, on by default, autologins root on every console and runs `nyx-recovery`, which can reset any account's password.
- **Expected:** Recovery without enabling privilege escalation for non-administrators (handoff 10 §12 privileges, §19).
- **Actual:** `recovery.nix:20-23` (default on), `:50-52` (`services.getty.autologinUser = "root"`). LUKS is the default (`templates/host/example-host.nix:10-12`), so the disk passphrase is the only barrier.
- **Reproduce / verify:** Boot the "recovery" entry; a root prompt appears without credentials.
- **Evidence:** as above
- **Affected versions:** nyxos `97f1573`
- **User impact:** On shared machines any person who can unlock the disk becomes root.
- **Recommended correction:** Ask for an administrator's password (`sulogin` against wheel, or a PAM check in nyx-recovery) except when no administrator can sign in.
- **Effort:** S
- **Dependencies:** NYX-SEC
- **Verification criteria:** Recovery asks for an admin password.

### NYX-UPD-001: System update plans don't show what will change before confirmation

- **Component:** nyx-system `crates/nyx-update`, `apps/system-manager/src/upgrade.rs`
- **Category:** UX
- **Severity:** P2
- **Status of feature:** partial
- **Description:** For `system`, the plan knows only the installed and head revisions of the channel; package versions and size are computed after the switch.
- **Expected:** Plan with resolved packages, current and available versions, download size, restart/reboot needs before confirmation (handoff 08 §7).
- **Actual:** `probe.rs:31-43,330-381` (revision only); `upgrade.rs:164-169,318-338` (`nix store diff-closures` after switching).
- **Reproduce / verify:** `nyx update system --dry-run --json` shows no package list.
- **Evidence:** as above
- **Affected versions:** nyx-system `6f0c47c`
- **User impact:** Users approve a system rebuild blind; kernel/reboot need known only afterwards.
- **Recommended correction:** Build to a result link first (already done), then show `diff-closures` and closure size and ask before `switch`.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** Dry run lists version changes and reboot requirement.

### NYX-UPD-002: The stable channel's nyx-packages input doesn't follow nyx-packages' stable

- **Component:** nyxos `flake.nix` on `stable`; `README.md:38-40`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** partial
- **Description:** README says stable has "nyx-packages pinned at its own `stable`", but `stable`'s `flake.nix:15-16` uses `github:nyxos-project/nyx-packages` (main); only the lock pins it. Promotion is manual (tag plus VM snapshot, `docs/dev-vm.md:140-143`), with no CI gate tying the tag to a green run.
- **Expected:** Tested, reproducible release channel (handoff 08 §3.4, §11).
- **Actual:** as above; `origin/stable` = `known-good/22`.
- **Reproduce / verify:** `git show origin/stable:flake.nix | rg nyx-packages`.
- **Evidence:** as above
- **Affected versions:** nyxos `stable` `7454358`
- **User impact:** A maintainer's `nix flake update` on stable would pull nyx-packages main.
- **Recommended correction:** Point stable at `nyx-packages/stable`; require the CI run on the tagged commit.
- **Effort:** S
- **Dependencies:** packaging-ci report
- **Verification criteria:** Stable's input URL ends in `/stable`; promotion script checks CI status.

### NYX-SET-001: Omarchy wording leaks into NyxOS Settings resets

- **Component:** nyx-settings `apps/settings/src/sections/about.rs`, `themes.rs`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** "Reset all" toasts "Back to your own config and Omarchy's defaults" on NyxOS; the appearance reset says it returns to Catppuccin Mocha though it returns to the administrator's default.
- **Expected:** Reset means the current NyxOS default (handoff 09 §10.1).
- **Actual:** `about.rs:177`; `themes.rs:591` vs `nyx-theme-core/src/lib.rs:154-165`.
- **Reproduce / verify:** Settings › About › changed options › Reset.
- **Evidence:** as above
- **Affected versions:** nyx-settings `7e76622`
- **User impact:** Confusing messages.
- **Recommended correction:** Platform-specific strings.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No "Omarchy" text on NyxOS reset paths.

### NYX-SET-002: Hyprland settings bypass the administrator layer, and there is no Settings IPC

- **Component:** nyx-settings `backend/store.rs`; nyxos `modules/home/hyprland.nix`; nyx-system `nyx-config`
- **Category:** architecture
- **Severity:** P3
- **Status of feature:** partial
- **Description:** NyxOS's Hyprland defaults are rendered into each user's `hyprland.lua` at build time and the user's choices live in `~/.config/nyx-settings/state.json`; nothing reads `/etc/nyxos/overrides/hyprland.toml`, so an administrator default for Hyprland has no effect. Settings offers no get/set/reset/subscribe interface; other programs use `nyx-system config` or a read-only action.
- **Expected:** Precedence user > device > administrator > NyxOS > built-in (handoff 09 §5); Settings IPC (§25).
- **Actual:** `modules/home/hyprland.nix:17,84`; only `backend/gestures.rs:327-333` reads the defaults copy; `nyx-settings/docs/configuration.md:16` (owner: Settings, `state.json`).
- **Reproduce / verify:** `nyx-system config set` an administrator Hyprland default (System Manager `SetDefault` for domain `hyprland`); Hyprland unchanged.
- **Evidence:** as above
- **Affected versions:** nyx-settings `7e76622`, nyxos `97f1573`
- **User impact:** Fleet/family administrators can't set desktop behaviour defaults.
- **Recommended correction:** Merge the `hyprland` domain's layers at render time in Settings' `settings.lua`; document the domain as user-only until then.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** An administrator Hyprland default applies to users who haven't changed it.

## Runtime tests to run in the VM

1. Theme consistency: `busctl --user call io.github.design_nexus.nyx.Theme /io/github/design_nexus/nyx/Theme io.github.design_nexus.nyx.Theme1 GetActiveTheme`; `jq '.tokens.colors["surface.secondary"], .tokens.colors["text.secondary"]' $XDG_RUNTIME_DIR/nyx/theme/system.json`; screenshot Nyx Calculator and the dock on a headless output and compare colours (NYX-THEME-001/002).
2. AI endpoint exposure and isolation: as a second user `curl -s 127.0.0.1:8080/v1/models`; then with `python3 -m http.server 8080` running before login, `systemctl --user status nyx-aid.socket` and `nyx-ai status` (NYX-AI-001/002).
3. Update planning and failure path: `nyx update --dry-run --json`, `nyx update system --dry-run`, `nyx update claude --dry-run`; then `nyx-system update` with a deliberately broken overrides file and check `/var/lib/nyx-system/history.jsonl`, `nixos-rebuild list-generations` and that `flake.lock` was restored.
4. Dictation and voice independence: on a base install press F9; `systemctl --user status nyx-voiced.socket`; `nyx-voice status --json`; `nyx-voice devices` (NYX-VOICE-001).
5. Connect failure isolation: `systemctl --user stop fluxd`; open Settings › Devices and the Control Center Devices tile, copy text (Nyx Clipboard), send a notification; `busctl --user call io.github.design_nexus.nyx.Notifications /io/github/design_nexus/nyx/Notifications io.github.design_nexus.nyx.Notifications1 Dnd`; restart fluxd and check reconnection within 30 s; `sudo nft list ruleset | grep 12100` (NYX-CONN-001).

## Runtime results (Phase D/F)

- **AI Core:** worker ready (PrismML llama.cpp b12128); load 5.3 s; endpoint confirmed
  unauthenticated (NYX-AI-001 / NYX-SEC-001); worker restarts after SIGKILL and the
  endpoint answers again; endpoint requests missing from statistics (NYX-PERF-002).
  NYX-AI-002 (port 8080 taken) not exercised.
- **Theme Engine:** live switch to Catppuccin Mocha reached the bar in 375 ms and a
  running app without restart, colours identical (`#1e1e2e`) in bar and app; a malformed
  `theme.toml` silently falls back to the system theme (NYX-THEME-003).
- **System Manager and updates:** offline message clear; rollback 4 s; failed build undone;
  interrupted change leaves overrides modified (NYX-REL-002); on an installed machine the
  flake lock breaks after the first GC (NYX-INST-002); `nyx update` can't check the system
  channel on the dev VM by design.
- **Connect:** fluxd stopped → clear "Flux isn't running / Start Flux" in Settings and the
  CLI; recovery on restart. Pairing untested (no phone).
- **Voice:** not exercised (no audio devices in the VMs).
- **Settings:** under a full disk, `nyx-system config set` reports "No space left on
  device"; 55/55 buttons named with the accessibility bridge forced on.
