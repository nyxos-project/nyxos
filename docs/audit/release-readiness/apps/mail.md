# Nyx Mail scorecard

- **Repository:** design-nexus/nyx-mail at `5235153582` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (installed per user from Welcome or the Store)
- **Purpose:** unified-inbox mail client with offline reading and a sync engine
- **Stack:** Rust/GTK4 window with WebKitGTK 6 message view; `nyx-maild` engine (async-imap, lettre, Microsoft Graph via reqwest, rusqlite FTS5) on D-Bus `io.github.design_nexus.nyx.MailEngine1`; credentials from nyx-accounts `afdc148` (native, no GOA/EDS)
- **Binaries / services:** `nyx-mail`, `nyx-maild`, `nyx-mail-glimpse` (Glimpse plugin in `share/nyx-mail/glimpse`); user unit `nyx-maild.service` started with `graphical-session.target` (`nyx-packages/pkgs/nyx-mail.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Engine and UI complete for IMAP/SMTP and Graph; Google/Microsoft accounts need a self-registered OAuth client |
| UX | 2 | Gmail-style keys, Undo for every action, auth banner to Settings; onboarding is developer-grade |
| Accessibility | 2 | 9 explicit accessible labels, 13 tooltips on 6 icon buttons |
| Reliability | 3 | 0 non-test `unwrap()`; ops queue with backoff; drafts saved as you type and on close; hardened unit |
| Integration | 2 | mailto handler, Glimpse plugin, Share, Assistant tools; plugin discovery for per-user installs unverified |
| Packaging | 2 | Unit, plugin and WebKit/TLS inputs present; depends on an accounts service still labelled "preview" |
| Maintainability | 3 | 62 tests incl. Dovecot integration tests; docs present but partly stale (GOA) |

## Functionality

Implemented (docs/PLAN.md phases 1-2 checked): unified inbox, conversations, FTS search,
compose/reply/forward with drafts (`apps/mail/src/compose.rs:402-441, 508-519`), archive/
trash/junk/star with Undo, Screener and categories, snooze, send later, follow-ups,
offline ops queue (docs/ARCHITECTURE.md "Sync"). HTML is sanitized with ammonia and shown
with JavaScript, navigation and remote loads off (ARCHITECTURE.md "Message view").
Data: `~/.local/share/nyx-mail/` (0700, `mail.sqlite` + `store/`); `nyx-maild` is the only
writer. Accounts: `apps/maild/src/accounts.rs:1-4` reads native nyx-accounts sessions.
EDS is not used and not needed; nyx-packages blocks nyx-core's EDS crates
(`nyx-packages/lib/default.nix:47-56`) and the NyxOS module has no EDS service.

## UX and accessibility (static)

Full keyboard map (README "Keys", F1). Explicit `update_property` labels in 9 places. No
hard-coded colours (theme tokens injected into the WebKit CSS).

## Reliability

`nyx-maild.service`: `Restart=on-failure`, `UMask=0077`, `NoNewPrivileges` (`apps/maild/data/nyx-maild.service`).
If the engine is down the window stays readable. `expect()`s guard startup only
(`apps/maild/src/engine.rs:92-96`, interface XML). Tests run against a throwaway Dovecot
(docs/TESTING.md).

## Integration and packaging

`io.github.design_nexus.nyx.Mail.desktop`: `x-scheme-handler/mailto`, Compose action; icon
present. Glimpse plugin (`apps/mail-glimpse/plugin.toml`, no network, read-only DB mount
by Glimpse). Assistant control tools (mail.search/read/draft; send needs a key press);
no action manifest installed. For per-user installs the module links Glimpse plugins only
for system-enabled apps (`nyx-packages/modules/nixos/default.nix:285-287`); the user unit
is linked by the `nyx-profile-units` generator (`default.nix:84-127`). Only Omarchy
reference: `ThemeMode::Omarchy` default (`apps/mail/src/prefs.rs:56`, follow system).

## Maintenance

62 tests. CI: check + release. docs/ARCHITECTURE.md:10, 40-42 still describe GOA. Pins:
nyx-accounts `afdc148` (behind its `main` `e0df68a`), nyx-glimpse `6f9f732`, nyx-share `3923640`.

## Runtime results

- Smoke test (Mail): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 885 / 720 ms (two warm runs), RSS 220 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- 29/29 buttons named. Per-user install fails after Calendar (NYX-PKG-008) on the installed system.

## Findings

### NYX-APP-MAIL-001: Google and Microsoft accounts need the user's own OAuth app registration

- **Component:** nyx-accounts `afdc148` (`docs/PROVIDERS.md`), nyx-settings `apps/settings/src/sections/native_accounts.rs`; consumed by nyx-mail
- **Category:** functionality
- **Severity:** P1
- **Status of feature:** partial
- **Description:** Mail advertises Google, Microsoft 365, Outlook.com and iCloud (README.md:3) and Welcome says "Email, with your online accounts". The pinned accounts service is an "isolated development preview": Google needs a Google Cloud project and Desktop OAuth client that the user creates and pastes in; Microsoft needs a self-made app registration, is untested with real accounts, and work/school (Microsoft 365) tenants are unsupported.
- **Expected:** A mainstream user can add Gmail/Outlook from Settings › Online Accounts without developer setup, or the docs and catalog limit the claim to IMAP/app-password providers.
- **Actual:** nyx-accounts `afdc148:docs/PROVIDERS.md:3-25` (preview, user-created clients, "/consumers authority exclusively"); Settings asks "Paste the client ID from your provider" (`native_accounts.rs:367, 427, 816`); nyx-accounts `main` `e0df68a` has the same text.
- **Reproduce / verify:** On NyxOS, Settings › Online Accounts › Google: the form requires a client ID (runtime).
- **Evidence:** as above; `nyx-mail/README.md:3`; `nyx-system/crates/nyx-catalog/catalog.toml:278-283`
- **Affected versions:** nyx-mail 5235153582; nyx-accounts afdc148 and e0df68a
- **User impact:** Most users can't connect Gmail or Outlook, the main mail providers.
- **Recommended correction:** Ship registered Nyx OAuth clients (with Google verification) or narrow README/catalog claims to IMAP/app-password accounts for 0.1.0.
- **Effort:** L
- **Dependencies:** Online Accounts audit (NYX-CONN/NYX-SET); NYX-APP-CALENDAR-001, NYX-APP-CONTACTS-001
- **Verification criteria:** A new Gmail and Outlook.com account sync without entering a client ID.

### NYX-APP-MAIL-002: Glimpse plugin from a per-user install is not linked where Glimpse looks

- **Component:** nyx-packages `modules/nixos/default.nix`; nyx-glimpse plugin discovery
- **Category:** packaging
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Welcome installs Mail into the person's Nix profile. The module adds `/share/nyx-mail/glimpse` to the system profile only when `nyx.mail.enable` is set; nothing does the same for profile installs.
- **Expected:** Mail search in Glimpse works however Mail was installed.
- **Actual:** `default.nix:285-287` (system-enabled packages only); no profile handling found in nyx-system or nyxos.
- **Reproduce / verify:** Install Mail from Welcome; open Glimpse, search `mail …` (runtime).
- **Evidence:** `nyx-packages/modules/nixos/default.nix:285-287`
- **Affected versions:** nyx-packages d69e87e
- **User impact:** The advertised mail search in Glimpse may be missing for Welcome installs; also affects Calendar, Notes, News.
- **Recommended correction:** Have Glimpse scan `~/.nix-profile/share/*/glimpse` and `/etc/profiles/per-user/$USER/share`, or register plugins at install.
- **Effort:** S
- **Dependencies:** Glimpse scorecard
- **Verification criteria:** Per-user Mail's plugin appears in Glimpse's plugin list.

### NYX-APP-MAIL-003: Architecture doc still describes GOA

- **Component:** nyx-mail `docs/ARCHITECTURE.md`, `README.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The diagram and "Engine" section say credentials come from `goa-daemon`; the code uses native nyx-accounts sessions. README says "Mail for Omarchy" and installs with curl.
- **Expected:** Docs match the shipped architecture.
- **Actual:** `docs/ARCHITECTURE.md:10, 40-42`; `apps/maild/src/accounts.rs:1-4`; nyx-accounts `afdc148:src/lib.rs:1` "No GOA or EWS dependencies".
- **Reproduce / verify:** `rg -n GOA nyx-mail/docs`
- **Evidence:** as above
- **Affected versions:** 5235153582
- **User impact:** Misleads maintainers and security review.
- **Recommended correction:** Rewrite the credentials section for nyx-accounts.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No GOA references outside migration notes.
