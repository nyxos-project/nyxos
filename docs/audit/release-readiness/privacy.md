# Privacy

Handoff 10 §13. Static review on 2026-11-12 of the checkouts in `~/Projects` (no builds,
no VM changes). Same revisions as [security.md](security.md), plus nyx-glimpse
`deecabf`, nyx-chat `38a8bae`, nyx-capture `06b4d57`, nyx-notification-center
`b0801d6`, nyx-bar `4a84c75`, nyx-maps `ef6fe24`. Claims marked "confirm at runtime"
weren't observed.

## Summary

| Area | Assessment | Worst |
| --- | --- | --- |
| Microphone | Nyx Voice starts on demand and only trusted programs may listen (`nyx-voice/apps/nyx-voiced/src/server.rs:34-48,135-172`). The Assistant, once a person enables its daemon, listens continuously for its wake word. The bar's privacy item shows mic, camera and PipeWire screencasts and is in the default layout (`nyx-bar/plugins/privacy/src/main.rs:1-7`, `nyx-core/crates/nyx-plugin/src/layout.rs:17-19`) | P2 (PRIV-002) |
| Camera | Face sign-in is opt-in per machine (`nyx-packages/modules/nixos/biometrics.nix:174-184`); the camera runs inside PAM (Irlume/Gaze, third-party; template storage not reviewed, confirm at runtime). The bar dot covers `/dev/video*` opened by apps | — |
| Screen capture | Any Wayland client can capture silently; the indicator misses non-PipeWire capture | P2 (PRIV-001) |
| Clipboard history | Good: Nyx Clipboard (Store tier) skips secrets, `x-kde-passwordManagerHint` copies, private mode and excluded apps; SQLite 0600 with age/count/size retention (`nyx-clipboard/crates/nyx-clipboard-core/src/sensitive.rs:1-60`, `classify.rs:10`, `crates/nyx-clipboard-store/src/lib.rs:1,128,382-405`, `apps/daemon/src/main.rs:4,57`). Not encrypted at rest (relies on disk encryption) | — |
| Notification history | 30-day retention, delete, per-app exclusions (`nyx-notification-center/crates/nyx-notify-store/src/lib.rs:9,120,135`), DB 0600 (`:350`). Readable by any same-user process over D-Bus | P3 (PRIV-005) |
| Search indexing | Good: Glimpse's file and semantic index is off with no folders until chosen (`nyx-glimpse/apps/glimpse/src/config.rs:53-62`); hidden folders and secret-looking names never indexed (`config.rs:250-274`); index 0600 in a private folder (`semantic.rs:64-73`) | — |
| AI prompts and conversations | Local by default: AI Core runs models on the machine; no cloud model provider URLs in Chat, Assistant, Glimpse or AI Core (only Hugging Face for downloads, `nyx-ai/.../hf.rs:258-261`). Chat stores conversations locally and has temporary chats (`nyx-chat/apps/chat/src/window.rs:361-369`, `store.rs:368`). Assistant `save_history = false`, logs exclude spoken content, 30-day retention (`nyx-assistant/apps/assistant/config/config.toml:243-246`) | — |
| Screenshots | Capture keeps 90 days of history with automatic OCR full-text index | P3 (PRIV-006) |
| File access | Assistant `files_read = "allow"` inside home but secret folders are guarded (`config.toml:161-170`; `assistant-tools/src/typed.rs:180`, `sandbox.rs:103-110`). Flux Browse PC off for new users (see PRIV-004) | P3 (PRIV-004) |
| Device sync (Nyx Connect) | Pairing needs user confirmation of a key; after pairing, clipboard and notifications go to the phone by default; Browse PC default fix only reaches new configs | P3 (PRIV-004) |
| Telemetry / outbound | No telemetry or analytics code in any Nyx repository. Default-on outbound: update checks to GitHub (daily user timer, `nyx-packages/modules/nixos/default.nix:524-548`; `nyx-settings/apps/settings/src/backend/updates.rs:75`), Flathub through the Store, Hugging Face only on model download. Third-party IP geolocation in Assistant, Chat and Maps | P3 (PRIV-003) |
| Network announcement | Avahi publishes this machine and Flux's service on every network (`default.nix:372-378`); hostname often holds a person's name | P3 (see security NYX-SEC-003) |

## Findings

### NYX-PRIV-001: Any Wayland client can capture the screen silently, and the indicator can't see it

- **Component:** nyxos `modules/home/hyprland.nix` (no permission rules); nyx-bar `plugins/privacy/src/main.rs:1-7`; nyx-assistant `crates/assistant-desktop/src/screen.rs:70-75`
- **Category:** privacy
- **Severity:** P2
- **Status of feature:** partial (static; confirm at runtime)
- **Description:** Hyprland exposes `wlr-screencopy` and toplevel export to every client unless its permission system is enforced (`ecosystem:enforce_permissions` with `permission` rules). NyxOS sets neither (`rg 'enforce_permissions|hl.permission|screencopy'` over nyxos, nyx-packages, nyx-hyprland: no hits). So any program, including the Assistant's on-demand vision which shells out to `grim`, can read the screen without a portal prompt. The bar's privacy item detects only PipeWire screencast nodes, `/dev/video*` and capture streams, so these captures show no violet dot. Capture's own recordings show `nyx.recording`, but its screenshots and other apps' grabs show nothing.
- **Expected:** §13 "Explicit permissions", "Appropriate user indicators" for screen capture.
- **Actual:** as above.
- **Reproduce / verify:** in the VM session, run `grim /tmp/x.png` from a terminal and watch the bar: no indicator. `hyprctl getoption ecosystem:enforce_permissions` → `0` expected.
- **Evidence:** above.
- **Affected versions:** nyxos `97f1573`, nyx-bar `4a84c75`
- **User impact:** any running app can screenshot passwords, messages and documents without consent or a visible sign.
- **Recommended correction:** Enable Hyprland's permission enforcement: allow screencopy only for the portal (`xdg-desktop-portal-hyprland`), Nyx Capture and the Assistant by store path, `ask` for others. Have the privacy item also show "screen read by <app>" from Hyprland's permission events or a Nyx Capture/Assistant D-Bus signal.
- **Effort:** M
- **Dependencies:** HYPR audit; NYX-SEC-002 (identity by path)
- **Verification criteria:** an unlisted program's `grim` is denied or prompts; Assistant vision shows an indicator while it looks.

### NYX-PRIV-002: The Assistant listens all the time once enabled, though its default mode is called push-to-talk

- **Component:** nyx-assistant `apps/assistant/config/config.toml:3,95-105,173-183,199-204`; `daemon/nyx-assistantd/src/app.rs:1875-1908`
- **Category:** privacy
- **Severity:** P2
- **Status of feature:** implemented, not verified (static; confirm at runtime)
- **Description:** The shipped config says `mode = "push-to-talk"` but also `[wake_word] enabled = true`. When the daemon is idle and the wake word is enabled, it keeps the microphone open (`app.rs:1889` `start_capture`) and transcribes each utterance with the streaming recognizer to look for "Echo" (`collect_wake_pcm`, `app.rs:1912-…`). Processing is local, but every conversation in the room is transcribed in memory, any audio source (a video, a call) can trigger it, and `[agent] mode = "autonomous"` runs permitted tools without asking (`config.toml:173-183`). The daemon starts only after the person enables it (`nyx-packages/modules/nixos/default.nix:394-414`), and the bar's mic dot should be lit the whole time (confirm at runtime).
- **Expected:** §13 "Explicit permissions", "Data minimization"; §14 Voice. The setting's name should match its behaviour, and continuous listening should be a separate, explicit choice.
- **Actual:** as above.
- **Reproduce / verify:** in the VM enable it (`systemctl --user enable --now nyx-assistantd`), stay silent, then `pw-dump | jq '.[] | select(.info.props["media.class"]=="Stream/Input/Audio") | .info.props["application.name"]'` → the assistant's stream is present while idle.
- **Evidence:** above.
- **Affected versions:** nyx-assistant `58ed80e`
- **User impact:** a person who enables "push to talk" gets an always-on microphone.
- **Recommended correction:** Default `wake_word.enabled = false`; make "Listen for 'Hey Echo'" an explicit toggle in Welcome/Settings with a clear notice; default agent mode `assisted` for voice-triggered requests; keep the mic dot visible while listening.
- **Effort:** S
- **Dependencies:** AI audit §14 (Assistant, Voice)
- **Verification criteria:** a fresh enable shows no capture stream until the push-to-talk key is held.

### NYX-PRIV-003: IP geolocation goes to a third party (ipapi.co) without consent

- **Component:** nyx-assistant `crates/assistant-core/src/location.rs:97`, `config/config.toml:234-241`; nyx-chat `apps/chat/src/tools/location.rs:66`; nyx-maps `src/location/geoclue.rs:192-193`
- **Category:** privacy
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** The Assistant (`[location] enabled = true`), Chat's location tool and Maps' GeoClue fallback send the machine's public IP to ipapi.co on demand to guess the city. It's on by default and not disclosed in the UI reviewed. GeoClue is already available (`default.nix:383-391`).
- **Expected:** §13 "No unapproved cloud transmission".
- **Actual:** as above.
- **Reproduce / verify:** ask the Assistant "what's the weather" with no city set; observe a TLS connection to ipapi.co (`ss -tnp` or `journalctl --user -u nyx-assistantd`).
- **Evidence:** above.
- **Affected versions:** nyx-assistant `58ed80e`, nyx-chat `38a8bae`, nyx-maps `ef6fe24`
- **User impact:** IP and query timing disclosed to an analytics-funded third party.
- **Recommended correction:** use GeoClue (with its own permission prompt) or the city in Settings; ask once before any IP lookup and say which service.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** no request to ipapi.co without a recorded consent.

### NYX-PRIV-004: Nyx Connect shares clipboard and notifications by default, and Browse PC's safe default reaches only new configs

- **Component:** nyxos `modules/nixos/apps.nix:86-95`; flux `v0.19.1` `internal/config/config.go:158`; nyx-settings `apps/settings/src/backend/connect.rs:69-115`
- **Category:** privacy
- **Severity:** P3
- **Status of feature:** implemented, not verified (static; confirm at runtime)
- **Description:** Upstream fluxd defaults `ShareHome`, `AutoClipboard`, `Notifications` and `CheckUpdates` to true. NyxOS writes `share_home = false` and `check_updates = false` only when `~/.config/flux/config.toml` doesn't exist yet, from a user activation script; fluxd starts with the graphical session and writes its own defaults if it wins the race, and machines that ran fluxd before keep `share_home = true`. After pairing, every desktop notification (including verification codes and message previews) and clipboard text go to the phone; Settings lists these accesses per device. Password-manager copies are skipped (`internal/desktop/clipboard.go:72-81`).
- **Expected:** §13 "Explicit permissions" for device synchronisation; handoff note "share_home default false".
- **Actual:** as above.
- **Reproduce / verify:** `cat ~/.config/flux/config.toml` on the VM and a freshly created account; `flux-cli status` (or Settings › Devices) shows accesses after pairing.
- **Evidence:** above.
- **Affected versions:** nyxos `97f1573`, flux `v0.19.1`
- **User impact:** more data leaves the computer than a person may expect when pairing.
- **Recommended correction:** set NyxOS defaults in the flux patch (`config.Load` defaults) instead of a first-run file; at pairing ask per access (clipboard, notifications, files); exclude notifications that carry codes unless allowed.
- **Effort:** S
- **Dependencies:** CONN audit (§15)
- **Verification criteria:** a new pairing starts with only the accesses the person ticked; upgraded machines show Browse PC off unless chosen.

### NYX-PRIV-005: Notification history is readable by any same-user process over D-Bus

- **Component:** nyx-notification-center `apps/notifyd/src/service.rs:34-58`
- **Category:** privacy
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `Inbox`, `Pinned`, `History(query)` and `Settings` answer any session-bus caller; notifications keep message bodies and verification codes for 30 days. Nyx Clipboard, by contrast, checks callers (`nyx-clipboard/apps/daemon/src/state.rs:114-140`). Flatpak apps can't reach it by default (filtered bus); unsandboxed programs can, and could also read the 0600 database.
- **Expected:** §13 "Sensitive-content exclusions"; consistent IPC boundaries.
- **Actual:** no caller check.
- **Reproduce / verify:** `busctl --user call io.github.design_nexus.nyx.Notifications /io/github/design_nexus/nyx/Notifications io.github.design_nexus.nyx.Notifications1 History s '{}'`
- **Evidence:** above.
- **Affected versions:** nyx-notification-center `b0801d6`
- **User impact:** low (same-user boundary); defence in depth for codes and messages.
- **Recommended correction:** restrict history methods to the Notification Center, Glimpse and Settings by trusted path (nyx-peer); drop codes from stored history after they expire.
- **Effort:** S
- **Dependencies:** NYX-SEC-002
- **Verification criteria:** `busctl` from a shell is refused.

### NYX-PRIV-006: Capture OCR-indexes every screenshot and keeps it for 90 days by default

- **Component:** nyx-capture `apps/capture/src/prefs.rs:71-77`, `crates/nyx-capture-core/src/store.rs:1,28-44`
- **Category:** privacy
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `history = true`, `retention_days = 90`, `ocr_on_capture = true`, `ocr_mode = "automatic"`: text in every screenshot (passwords, chats, account numbers) lands in an FTS5 table. Capture is base tier on every install (`nyxos/modules/nixos/apps.nix:49`). It's local and the person took the screenshot, but the searchable text outlives the image's purpose.
- **Expected:** §13 "Data minimization", "Retention controls".
- **Actual:** as above.
- **Reproduce / verify:** take a screenshot of text; `sqlite3 ~/.local/share/nyx-capture/*.db 'select ocr from captures limit 1'` (path: confirm at runtime).
- **Evidence:** above.
- **Affected versions:** nyx-capture `06b4d57`
- **User impact:** sensitive on-screen text persists in plaintext for three months.
- **Recommended correction:** OCR on request (or for the history search only when enabled), 30-day default, skip OCR when a password manager or lock surface was on screen, and a "clear history" in Settings.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** defaults changed; OCR text absent unless requested.

## Runtime confirmation (Phase D, dev VM)

- **NYX-PRIV-001 confirmed:** `ecosystem:enforce_permissions` is false; `grim` run as an
  ordinary program captured the whole screen without a prompt; a capture taken right after
  shows no indicator in the bar (logs/runtime-security-probes.txt,
  shots/after-silent-grim.png).
- **Connect defaults:** the dev user's `~/.config/flux/config.toml` has `share_home =
  false`, `check_updates = false` (NYX-PRIV-004's Browse PC fix in place for this user).
- **AI prompts:** requests to the local endpoint stayed on 127.0.0.1; no outbound
  connection was observed during inference (only fluxd, avahi, sshd and loopback listeners;
  logs/runtime-listening.txt). Outbound traffic wasn't captured, so "no cloud
  transmission" is not verified beyond that.
- NYX-PRIV-002 (Assistant always listening) not exercised: the VM has no microphone.
