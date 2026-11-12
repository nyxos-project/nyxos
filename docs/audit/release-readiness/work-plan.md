# Work plan: everything left from the audit

Every open finding (5 P1 partly or not done, 88 P2, 126 P3) in twelve workstreams, in a
suggested order. Each P1 and P2 item has its own choices; P3 items are grouped with
choices per group. **A** is the recommendation. Every item also has an implicit **D:
defer past 0.1** (it then goes into [known limitations](../../guide/known-limitations.md));
it's only written out where deferring is the recommendation.

How to answer: tell me per workstream ("W1 all A, except SEC-006 B"), or edit the
**Choice** column. Global decisions G1–G10 come first because several items depend on
them. Effort: S hours, M days, L weeks. Full findings: [issues.md](issues.md).

Already done: see the progress table in [remediation.md](remediation.md#progress-2026-11-12-after-the-audit).

## Decisions (2026-11-12)

- **G1 (Ken's own answer):** Lyra, Assistant and Containers ship in 0.1 and are made ready
  for it (their W5 items are required, not optional). **Pulse is out of 0.1**: removed
  from Welcome and the catalog (the package stays in nyx-packages); its findings
  (PULSE-001/002/004, SEC-014) wait until it's back.
- **G2: C**, NyxOS only. Omarchy code paths are removed over time. Until the laptop moves
  to NyxOS, removals keep apps runnable on plain Hyprland/Arch (they lose Omarchy-only
  features, not the ability to start).
- **G3–G10: A.**
- **Items: A everywhere** unless noted.

## Global decisions

| # | Decision | A (recommended) | B | C | Choice |
| --- | --- | --- | --- | --- | --- |
| G1 | First-release scope | Ship base + most Welcome apps; Lyra, Pulse, Assistant and Containers as a labelled **Preview** (Store only, "preview" badge) | Ship everything as is, document caveats | Cut Preview apps from 0.1 entirely | own (see above) |
| G2 | Omarchy as a platform | **NyxOS first**: NyxOS paths, docs and wording by default; Omarchy code kept behind platform checks | Equal dual-platform (keep both, fix only what breaks NyxOS) | NyxOS only: remove Omarchy code paths over time | C |
| G3 | Google/Microsoft accounts | **IMAP/CalDAV/app passwords** as the supported path for 0.1; "your own OAuth client" kept as advanced | Register project OAuth clients (Google verification, weeks; Microsoft app registration) | Keep bring-your-own-client only | A |
| G4 | Local AI endpoint (127.0.0.1:8080) | **Off by default**, Settings › AI turns it on for coding tools, with a token file and Host check | Always on with token + Host/Origin check | Keep as is (document) | A |
| G5 | Nyx Connect's network exposure | **Port closed until pairing starts or a device is paired**, then only on trusted networks | Open on every network after the first pairing | Keep as is | A |
| G6 | Screen capture | **Hyprland permissions on**: only the portal, Capture and the Assistant capture directly; others go through the portal's prompt | Bar indicator for capture, no gating | Keep as is | A |
| G7 | Recovery console | **Ask for an administrator's password** (open only if no admin has one) | Keep open, warn in the boot menu | Keep as is | A |
| G8 | Shell failure domain | **OnFailure unit**: after the start limit, notify and offer "Restart the shell"; raise the limit to 10/min | Split Bar into its own Quickshell process (two runtimes) | Both | A |
| G9 | Release signing | **Signed tags** (SSH/minisign) verified by `nyx update` before moving the channel pin; ISO + SHA256SUMS + signature on releases | GitHub artifact attestations only | Defer | A |
| G10 | Pace and rollout | **One workstream at a time**, NyxOS VM rebuilt once per workstream, `stable` promoted after W1–W3 | Smaller batches by repository | Everything, then one rollout | A |

## W1 Security and privacy

Duplicates are folded: SEC-001 = AI-001, SEC-003 = CONN-001, SEC-005 = SYS-001,
SEC-007 = VOICE-002, PRIV-002 = APP-ASSISTANT-003.

| ID | Issue | A (recommended) | B | Effort | Choice |
| --- | --- | --- | --- | --- | --- |
| SEC-001 / AI-001 | AI endpoint needs no key, no Host check | Per G4 | Host/Origin check + JSON content type only | S | |
| AI-002 | Port 8080 taken breaks AI Core for apps | Separate optional `nyx-aid-openai.socket` (off by default) | Daemon binds TCP itself after start | S | |
| AI-004 | Any program can run trusted actions via `nyx-actions --yes` | Treat the CLI as untrusted unless on a TTY with a prompt | Remove the CLI from trusted-bin | M | |
| SEC-002 | App identity by path is spoofable; keyd trusts `~/.local/bin` | On NixOS trust only `/etc/nyx/trusted-bin`; keyd shows polkit text from the verified program | Also verify the binary's store path hash | S | |
| SEC-003 / CONN-001 | fluxd port open on every network | Per G5 | Settings › Devices toggle, open by default | M | |
| SEC-004 | User in `input` group | Remove `input` (logind ACLs cover the seat); udev `uaccess` per device where a feature needs it | Keep, document | S | |
| SEC-005 / SYS-001 | Recovery is a passwordless root console | Per G7 | | S–M | |
| SEC-006 | Webcam face (Gaze) can unlock sudo/polkit/login | Assert Gaze only for `lock` unless `allowWebcamFace = true` | Require IR camera (Irlume) for every surface | S | |
| SEC-007 / VOICE-002 | Voice models downloaded without checksums | Pin URLs to commits, verify SHA-256, safe extraction | | S | |
| SEC-008 | No release signing; user apps auto-update | Per G9 | | M | |
| PRIV-001 | Silent screen capture | Per G6 | | M | |
| PRIV-002 / APP-ASSISTANT-003 | Assistant listens all the time once enabled | Wake word off by default; explicit toggle with notice; mic indicator | Ask on first enable | S | |
| APP-ASSISTANT-004 | Assistant uses network services without disclosure | First-run choices for location and web search | Note in catalog only | S | |
| APP-ARCHIVE-001 | Archive passwords visible in the process list | Password through 7-Zip's stdin | | S | |
| APP-CLOUD-001 | Cloud credentials reversible in rclone.conf | Encrypted rclone config, password in Secret Service | Tokens via env at mount time | M | |
| APP-TORRENTS-001 | Search plugins run Python from any URL | Warning + HTTPS only + private temp dir | Also run plugins under bubblewrap | S | |
| APP-PULSE-001 | Telegram API id/hash in source | Build-time env set by nyx-packages, prefs override kept | Users supply their own (setup step) | S | |

P3 group **W1-P3** (SEC-009 PR builds push to the cache, SEC-010 biometrics trusted-bin
overwritten, SEC-011 locker trusts `$USER`, SEC-012 System Manager reads open to all,
SEC-013 security docs claim unshipped features, SEC-014 shared Telegram credential,
PRIV-003 ipapi.co without consent, PRIV-004 Connect relays clipboard/notifications by
default, PRIV-005 notification history readable over D-Bus, PRIV-006 Capture OCR keeps 90
days, APP-CHAT-002 web tools on and keys in plain settings, APP-HOME-002 plain-HTTP Home
Assistant accepted, APP-LYRA-004 Google cookies unencrypted, APP-MEDIA-PLAYER-003 TMDB key
in plain settings, APP-PULSE-004 prebuilt call engine):
**A** fix all except PULSE-004 (document) · **B** fix SEC-009..012 and PRIV-003..005 only ·
**C** defer all. Choice: ___

## W2 Shell, sign-in and accessibility

| ID | Issue | A (recommended) | B | Effort | Choice |
| --- | --- | --- | --- | --- | --- |
| SHELL-001 | Crash loop leaves no bar/dock/launcher | Per G8 | | M | |
| SHELL-002 | Glimpse unavailable while Shell Core is down | Local fallback: Glimpse opens/closes itself when Shell Core isn't connected | Only fix the stale "open" state on reconnect | S | |
| REL-003 | Hot-plugged monitor gets no bar or dock | Surfaces follow `Quickshell.screens` (Variants); test with a headless output | Restart surfaces on Shell Core monitor events | S–M | |
| REL-002 | Interrupted System Manager change leaves overrides modified | Stage overrides; rename into place after a successful switch | Journal + replay on start | S–M | |
| SHELL-005 | Dock, bar, Control Center need a pointer | `Nyx.Ui` controls with focus and `Accessible` names; keyboard paths per surface | Keyboard only now, screen reader later | M | |
| A11Y-002 + THEME-002 | Contrast below WCAG AA; Mocha isn't Catppuccin's palette | Fix Mocha's roles (subtext0/1), raise nyx-theme-core's check to 4.5:1 text / 3:1 borders, adjust built-ins | Make Nyx Dark the default instead | M | |
| APP-GREETER-001 | Greeter dead end when greetd fails | Quit on `Broken` so greetd restarts it, plus "Try again" | | S | |
| APP-GREETER-002 | No layout or Caps Lock indicator | Show both beside the password | | S | |
| APP-GREETER-003 | No screen reader at login | AT bus in the greeter session + Super+Alt+S toggles Orca; Orca in the catalog | Defer to 0.2 | M | |
| HYPR-001 / HYPR-002 | Fullscreen workspaces: untested with games/video/browsers; Dock and Bar don't model them | Test matrix in the VM; teach Dock/Bar the named workspaces | Turn `fullscreen_own_workspace` off by default for 0.1 | M | |
| HYPR-003 | Virtual monitors exposed despite a confirm-timeout hang | Label "Experimental" in Settings; investigate the hang | Hide until fixed | S | |

P3 group **W2-P3** (SHELL-003 Glimpse and panels both hold the keyboard, SHELL-004
brightness polled every 2 s, SHELL-007 dock swipe following inactive, SHELL-008 GTK Aura
overlaps Nyx Bar, APP-ASSISTANT-005 same for Aura, UX-003 login wordmark cut and session
name, A11Y-003 Store buttons unnamed, APP-MUSIC-002 / APP-OFFICE-002 tooltip-only names,
APP-CALCULATOR-002 graph ignores theme, APP-AGENTS-002 terminal inaccessible, THEME-003
corrupt theme.toml replaced silently, THEME-004 theme installs clone whole repositories
unbounded, THEME-005 stale Nyx Dark defaults, UX-001 launcher helper entries that open
nothing, REL-001 journal noise): **A** fix all · **B** fix SHELL-003, UX-003, THEME-003, REL-001 only · **C** defer.
Choice: ___

## W3 Installer and dual boot

| ID | Issue | A (recommended) | B | Effort | Choice |
| --- | --- | --- | --- | --- | --- |
| APP-INSTALLER-002 | Failed install beside Windows leaves its partitions | Detect our GUIDs and offer "Remove what the failed install made" | Delete automatically on failure | S | |
| APP-INSTALLER-003 | No BitLocker/Secure Boot guidance; docs claim TPM2 | Warn when a BitLocker volume is found; correct the claims | Implement TPM2 unlock enrolment | S / L | |

P3 **W3-P3** (APP-INSTALLER-004 512-byte sector assumption, APP-WELCOME-002 Welcome can
run twice or close mid-apply): **A** fix both · **C** defer. Choice: ___

## W4 Data safety in apps

| ID | Issue | A (recommended) | B | Effort | Choice |
| --- | --- | --- | --- | --- | --- |
| APP-NOTEPAD-001 | Saving a non-UTF-8 file corrupts accented text | Remember the encoding; save in it (encoding_rs), ask if impossible | Refuse to save over, offer Save As UTF-8 | S | |
| APP-PDF-001 | "Edit text" leaves original words extractable | Warn in the edit UI + real redaction that removes covered text | Warning only | M | |
| APP-PHOTOS-002 | Saved edits drop EXIF | Copy EXIF, reset Orientation | | S | |

P3 **W4-P3** (APP-NOTEPAD-002 closed tab's text lost on quit before Undo, APP-PDF-002 save
not fsynced and resets permissions, APP-ARCHIVE-002 extraction safety relies on 7-Zip only,
APP-INSTALLER-004 is in W3): **A** fix all · **C** defer. Choice: ___

## W5 Advertised features

| ID | Issue | A (recommended) | B | C | Effort | Choice |
| --- | --- | --- | --- | --- | --- | --- |
| APP-CONTAINERS-001 | Podman not supported (wording fixed) | Add rootless Podman as a Docker-API socket candidate | Keep "Incus and Docker" | | S–M | |
| APP-PASSWORDS-001 | No browser autofill (wording fixed) | Publish the extension (AMO, Chrome Web Store), register hosts for per-user installs | Keep without autofill for 0.1 | | M | |
| APP-MAIL-001, CALENDAR-001, CONTACTS-001 | Google/Microsoft need own OAuth client | Per G3 | | | S–L | |
| APP-ASSISTANT-001 (rest) | ~18 desktop voice commands still Omarchy's | Map them to NyxOS (nyx-theme, hyprctl Lua, nyx-system) or drop from defaults | Drop unmapped commands from defaults | | M | |
| APP-PULSE-002 | Calls unverified | Run the interop matrix; drop "with calls" if it fails | Mark calls "preview" | | M | |
| APP-REMINDERS-001 | Sync rests on an unverified accounts preview | Validate providers; mark sync preview until then | | | M | |
| APP-LYRA-001/002/003 | Private YouTube API; no CI; memory | Per G1 (Preview); add CI from nyx-music; re-measure memory | Keep in Welcome, add CI | | S–M | |
| APP-MAPS-001 | Directions use the public OSRM demo server | A sanctioned provider with a key setting | Keep OSRM, label it | | M | |
| APP-MAPS-002 | Per-user Maps has no GeoClue | GeoClue on for the desktop; ask before IP fallback | | | S | |
| APP-GIT-001 | HTTPS/SSH push needs setup NyxOS lacks | `git-credential-libsecret` + a GTK askpass by default | In-app credential prompt | | M | |
| APP-THEATER-001 | No MPRIS | Port Media Player's `mpris.rs` | | | S | |
| APP-CHAT-001 / VOICE-003 | Chat's own whisper/Piper stack | Use Nyx Voice; keep the old runners as fallback | Remove voice from Chat for 0.1 | | M | |

P3 **W5-P3** (APP-FONTS-001 packaged but not offered, APP-FONTS-002 undocumented Google
endpoints, APP-CLOUD-002 Store item with no visible app, APP-TRANSFER-001 Store text wrong,
APP-MEDIA-PLAYER-002 / APP-THEATER-003 video MIME types and default handler, APP-NEWS-001
reserved features shown, APP-TORRENTS-002 port blocked / UPnP on): **A** fix all (Fonts
into the Store) · **B** catalog/MIME items only · **C** defer. Choice: ___

## W6 NyxOS correctness (Omarchy leftovers that run on NyxOS)

Depends on G2.

| ID | Issue | A (recommended) | B | Effort | Choice |
| --- | --- | --- | --- | --- | --- |
| APP-SETTINGS-001 | VPN install/import run Omarchy/pacman | Gate on Omarchy; NyxOS uses the catalog/System Manager and `nmcli` | Hide on NyxOS | S | |
| APP-CONTAINERS-002 | "Fix" runs Arch commands via pkexec | Detect NixOS; link to catalog items; drop VTE check | | S | |
| APP-CONTAINERS-003 | Root-equivalent groups not explained | Risk sentence per group; Fix goes through the catalog | | S | |
| APP-BIOMETRICS-001 | Sign-in page shows Arch-only actions | NyxOS branch: configure surfaces through the System Manager | Read-only status on NyxOS | M | |
| APP-BIOMETRICS-002 | Password waits behind fingerprint/face in the prompt | Cancel biometrics on typing; parallel methods like the locker | | M | |
| APP-CAPTURE-001 | Webcam overlay needs Omarchy's window rule | Rule in NyxOS's Hyprland defaults | Capture sets it at runtime | S | |
| APP-PHOTOS-001 | "Set as background" Omarchy-only | Through nyx-themed's D-Bus API | | S | |
| APP-CLIPBOARD-001, APP-AGENTS-001 | Packaged Settings pages never load | Settings reads `share/nyx-settings/extensions` in `XDG_DATA_DIRS` | | S | |
| VOICE-001 | Dictation not wired (Settings says F9) | Merge the F9 bindings; Nyx Voice on by default (socket-activated) | Hide the Settings text when absent | S | |
| APP-BACKUP-002 | Offline disk recovery offered but can't work | Hide on NixOS; find restic on PATH | | S | |

P3 **W6-P3** (APP-ACTIVITY-001, APP-FILES-002, APP-GIT-002, APP-WEATHER-001,
APP-PULSE-003, APP-ASSISTANT-008, APP-BACKUP-004, APP-SHARE-002, APP-STORE-002,
APP-BIOMETRICS-003/004, APP-CONTAINERS-004, APP-PASSWORDS-003, SET-001, ARCH-009, UX-002,
UX-004): **A** fix all · **B** only user-visible wording and errors (ACTIVITY-001,
FILES-002, GIT-002, PULSE-003, SET-001, UX-002, UX-004) · **C** defer. Choice: ___

## W7 Integration (actions, Glimpse, per-user apps)

| ID | Issue | A (recommended) | B | Effort | Choice |
| --- | --- | --- | --- | --- | --- |
| APP-MAIL-002 | Glimpse doesn't find per-user plugins | Glimpse scans profile `share/*/glimpse` | Register plugins at install | S | |
| APP-CALENDAR-002 / PKG-009 (rest) | Per-user D-Bus activation/actions | Verify after the stable promotion; fix what remains | | S | |
| AI-003 | Assistant ignores the shared action registry | Feed the registry into its tool catalog | Defer to 0.2 | M | |
| APP-ASSISTANT-002 | No launcher entry or icon | Desktop entry opening Settings › Assistant, offering to enable | | S | |

P3 **W7-P3** (APP-CAPTURE-002, APP-MEDIA-PLAYER-001, APP-THEATER-002, APP-TORRENTS-003,
APP-FONTS-003, APP-CONTACTS-003 action manifests; APP-GLIMPSE-001 a path-less hit panics
search; APP-CHAT-003 stale text): **A** fix all (GLIMPSE-001 first: it's a crash) ·
**B** GLIMPSE-001 only · **C** defer. Choice: ___

## W8 Updates and the System Manager

| ID | Issue | A (recommended) | B | Effort | Choice |
| --- | --- | --- | --- | --- | --- |
| UPD-001 | Plans don't show package changes before confirming | Build first, show `diff-closures` + size, then ask | Show the changed Nyx app list only | M | |

P3 **W8-P3** (UPD-002 stable's nyx-packages input follows main, SEC-012 is in W1, UX-004
in W6): **A** point stable at nyx-packages' stable branch in promote-stable · **C** defer.
Choice: ___

## W9 Build, CI and dependencies

| ID | Issue | A (recommended) | B | Effort | Choice |
| --- | --- | --- | --- | --- | --- |
| PKG-002 + THEME-001 | Apps on 10 nyx-core / 7 nyx-design revisions | Re-pin script + nyx-packages check failing on more than one revision | GTK apps take resolved tokens from nyx-themed at runtime | M | |
| PKG-001 / APP-FILES-001 | Files' safety tests skipped everywhere | Run the full suite as a NixOS VM test in CI | In the dev VM before each pin bump | M | |
| CI-004 | App CI never runs on push; 16 repos have none | `push: [main]` everywhere + a minimal check workflow for the 16 | Rely on nyx-packages' package builds | M | |
| CI-005 | ISO not built by CI; release has no artifacts | ISO in checks + release workflow with SHA256SUMS and signature (G9) | ISO in checks only | M | |
| DEP-001 | No dependency monitoring | Scheduled `cargo deny check advisories` over every pinned Cargo.lock, opening issues | Renovate | M | |
| DEP-003 | Nine hand-pinned packages | Table with reasons and review dates + CI check when nixpkgs catches up | | M | |
| DEP-004 | Forks with single-person upkeep | Upstreaming plan per fork (PrismML, flux, Hyprland, nixpkgs patches) | Document only | L | |
| HYPR-004 | No compositor patch tests | Run hyprtester for the series in nyx-packages' checks | | M | |
| APP-BACKUP-003, APP-WELCOME-001, APP-LYRA-002 | Untested critical paths / no CI | Smoke scripts in the VM; Welcome apply tests on a private bus; Lyra CI | | M | |
| APP-NOTES-001 | Two nyx-core revisions, old AI client | Part of PKG-002 re-pin | | S | |
| APP-CALCULATOR-001, APP-PASSWORDS-002 | License file / metadata wrong | Add LICENSE; fix recipe license | | S | |

P3 **W9-P3** (PKG-003..006, CI-006, CI-007, DEP-002, DEP-005, HYPR-005..009,
APP-ASSISTANT-007, APP-GLIMPSE-002, APP-SETTINGS-003, APP-CLIPBOARD-002, APP-HOME-001,
APP-MAPS-003, APP-TRANSFER-002, APP-CALCULATOR-003): **A** fix all · **B** CI-007, DEP-002,
PKG-005 (debug symbols), HYPR-007 only · **C** defer. Choice: ___

## W10 Architecture

| ID | Issue | A (recommended) | B | Effort | Choice |
| --- | --- | --- | --- | --- | --- |
| ARCH-001 | Shell components keep their own Hyprland watchers | Move Dock, Switcher and Bar host onto Shell Core's state | **D**: after 0.1 (recommended timing) | L | |
| ARCH-002 | Surfaces bypass the overlay registry | Wrap each surface in `OverlaySurface`; retire `Panel1` with the QML NC/Switcher | **D**: after 0.1 | M | |

P3 **W10-P3** (ARCH-003..008, ARCH-010, SET-002, SHELL-006, PERF-001, PERF-002):
**A** defer all past 0.1 except PERF-002 (small) · **B** fix all now · **C** defer all.
Choice: ___

## W11 Documentation

| ID | Issue | A (recommended) | B | Effort | Choice |
| --- | --- | --- | --- | --- | --- |
| DOC-002 | 28 READMEs present apps as Omarchy software | One README template (NyxOS first, Omarchy second per G2), applied to every release app | Only base and Welcome apps | M | |

P3 **W11-P3** (DOC-003..005, SEC-013, ARCH-008, HYPR-005, and the app doc items:
ARCHIVE-003, ASSISTANT-006, CALCULATOR-003, CALENDAR-003, CONTACTS-002, CONTAINERS-005,
FONTS-003, HOME-003, MAIL-003, MAPS-003, MEDIA-PLAYER-004, MUSIC-001, NEWS-002,
NOTEPAD-003, NOTES-002, OFFICE-003, PASSWORDS-004, PDF-003, PHOTOS-003, PULSE-005,
REMINDERS-002, SETTINGS-002, STORE-001, TORRENTS-003, WEATHER-002): **A** fix all with
DOC-002 (same pass) · **B** DOC-003..005 only · **C** defer. Choice: ___

## W12 Hardware

| ID | Issue | Plan | Choice |
| --- | --- | --- | --- |
| HW-001 | No physical hardware tested | Later, as you said: two laptops (Intel, AMD), an NVIDIA desktop, a HiDPI display; results into hardware.md | later |

## Suggested order

1. G1–G10 answered.
2. W1 security, W2 shell/accessibility, W3 installer (release gates C, D, G), then promote
   `stable`.
3. W4 data safety, W6 NyxOS correctness, W7 integration (mostly S items).
4. W5 advertised features (depends on G1, G3).
5. W8, W9 (CI and dependency automation keep the rest from regressing), W11 docs.
6. W10 architecture after 0.1; W12 hardware when machines are available.
