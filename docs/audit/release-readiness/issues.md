# Issue register

Every finding in this audit, generated from the reports by [evidence/scripts/issues.py](evidence/scripts/issues.py). Severity follows [evidence/FINDINGS-FORMAT.md](evidence/FINDINGS-FORMAT.md); each ID links to the full finding (description, evidence, reproduction, fix, verification).

| Severity | Count |
| --- | ---: |
| P0 | 1 |
| P1 | 15 |
| P2 | 89 |
| P3 | 127 |
| **Total** | **232** |

## P0

| ID | Title | Report |
| --- | --- | --- |
| [NYX-INST-001](installation.md#nyx-inst-001-the-010-live-usb-cant-install-mnt-doesnt-exist) | The 0.1.0 live USB can't install: `/mnt` doesn't exist | installation.md |

## P1

| ID | Title | Report |
| --- | --- | --- |
| [NYX-A11Y-001](ux-accessibility.md#nyx-a11y-001-accessibility-is-switched-off-for-every-session) | Accessibility is switched off for every session | ux-accessibility.md |
| [NYX-APP-ASSISTANT-001](apps/assistant.md#nyx-app-assistant-001-shipped-voice-commands-and-app-launches-call-omarchy-tools-that-nyxos-doesnt-have) | Shipped voice commands and app launches call Omarchy tools that NyxOS doesn't have | apps/assistant.md |
| [NYX-APP-BACKUP-001](apps/backup.md#nyx-app-backup-001-scheduled-backups-stop-silently-after-an-update-and-garbage-collection) | Scheduled backups stop silently after an update and garbage collection | apps/backup.md |
| [NYX-APP-CONTAINERS-001](apps/containers.md#nyx-app-containers-001-catalog-advertises-podman-but-the-app-has-no-podman-backend) | Catalog advertises Podman, but the app has no Podman backend | apps/containers.md |
| [NYX-APP-INSTALLER-001](apps/installer.md#nyx-app-installer-001-the-chosen-keyboard-layout-isnt-used-while-typing-the-password-and-passphrase-but-is-used-at-sign-in) | The chosen keyboard layout isn't used while typing the password and passphrase, but is used at sign-in | apps/installer.md |
| [NYX-APP-MAIL-001](apps/mail.md#nyx-app-mail-001-google-and-microsoft-accounts-need-the-users-own-oauth-app-registration) | Google and Microsoft accounts need the user's own OAuth app registration | apps/mail.md |
| [NYX-APP-OFFICE-001](apps/office.md#nyx-app-office-001-saving-a-wordexcelpowerpoint-file-in-place-silently-drops-what-office-didnt-import) | Saving a Word/Excel/PowerPoint file in place silently drops what Office didn't import | apps/office.md |
| [NYX-APP-PASSWORDS-001](apps/passwords.md#nyx-app-passwords-001-welcome-advertises-autofill-but-nyxos-ships-no-browser-extension) | Welcome advertises autofill, but NyxOS ships no browser extension | apps/passwords.md |
| [NYX-APP-SHARE-001](apps/share.md#nyx-app-share-001-nyxoss-firewall-blocks-nearby-sharings-port-so-phones-and-computers-cant-send-to-nyxos) | NyxOS's firewall blocks nearby sharing's port, so phones and computers can't send to NyxOS | apps/share.md |
| [NYX-CI-001](packaging-ci.md#nyx-ci-001-distribution-ci-has-been-red-for-two-days-at-a-format-check-so-nothing-is-built-or-tested) | Distribution CI has been red for two days at a format check, so nothing is built or tested | packaging-ci.md |
| [NYX-CI-002](packaging-ci.md#nyx-ci-002-no-branch-protection-stable-is-promoted-by-hand-with-no-gate) | No branch protection; `stable` is promoted by hand with no gate | packaging-ci.md |
| [NYX-CI-003](packaging-ci.md#nyx-ci-003-stable-is-behind-010-so-a-010-install-moves-backwards-on-its-first-update) | `stable` is behind 0.1.0, so a 0.1.0 install moves backwards on its first update | packaging-ci.md |
| [NYX-HW-001](hardware.md#nyx-hw-001-no-physical-hardware-has-been-tested) | No physical hardware has been tested | hardware.md |
| [NYX-INST-002](installation.md#nyx-inst-002-installed-machines-lose-the-ability-to-change-the-system-after-the-first-weekly-garbage-collection) | Installed machines lose the ability to change the system after the first weekly garbage collection | installation.md |
| [NYX-PKG-008](packaging-ci.md#nyx-pkg-008-two-nyx-apps-that-start-session-services-cant-both-be-installed-per-user) | Two Nyx apps that start session services can't both be installed per user | packaging-ci.md |

## P2

| ID | Title | Report |
| --- | --- | --- |
| [NYX-A11Y-002](ux-accessibility.md#nyx-a11y-002-themes-pass-nyxs-own-contrast-check-but-fail-wcag-aa-for-secondary-text-and-borders) | Themes pass Nyx's own contrast check but fail WCAG AA for secondary text and borders | ux-accessibility.md |
| [NYX-AI-001](infrastructure.md#nyx-ai-001-the-openai-compatible-endpoint-on-1270018080-is-unauthenticated-and-on-by-default) | The OpenAI-compatible endpoint on 127.0.0.1:8080 is unauthenticated and on by default | infrastructure.md |
| [NYX-AI-002](infrastructure.md#nyx-ai-002-the-ai-core-socket-unit-fails-for-everyone-when-port-8080-is-taken) | The AI Core socket unit fails for everyone when port 8080 is taken | infrastructure.md |
| [NYX-AI-003](infrastructure.md#nyx-ai-003-nyx-assistant-doesnt-use-the-shared-action-registry) | Nyx Assistant doesn't use the shared action registry | infrastructure.md |
| [NYX-AI-004](infrastructure.md#nyx-ai-004-any-program-can-run-confirmed-trusted-app-actions-through-the-nyx-actions-cli) | Any program can run confirmed, trusted app actions through the `nyx-actions` CLI | infrastructure.md |
| [NYX-APP-AGENTS-001](apps/agents.md#nyx-app-agents-001-packaged-settings-page-is-never-loaded) | Packaged Settings page is never loaded | apps/agents.md |
| [NYX-APP-ARCHIVE-001](apps/archive.md#nyx-app-archive-001-archive-passwords-are-visible-to-other-users-in-the-process-list) | Archive passwords are visible to other users in the process list | apps/archive.md |
| [NYX-APP-ASSISTANT-002](apps/assistant.md#nyx-app-assistant-002-no-launcher-entry-or-icon-installed-assistant-is-invisible-outside-settings) | No launcher entry or icon; installed Assistant is invisible outside Settings | apps/assistant.md |
| [NYX-APP-ASSISTANT-003](apps/assistant.md#nyx-app-assistant-003-wake-word-is-on-by-default-so-enabling-the-assistant-starts-always-on-listening-without-a-consent-step) | Wake word is on by default, so enabling the Assistant starts always-on listening without a consent step | apps/assistant.md |
| [NYX-APP-ASSISTANT-004](apps/assistant.md#nyx-app-assistant-004-network-services-used-by-default-without-disclosure-ip-geolocation-web-search-google) | Network services used by default without disclosure (IP geolocation, web search, Google) | apps/assistant.md |
| [NYX-APP-ASSISTANT-005](apps/assistant.md#nyx-app-assistant-005-aura-doesnt-account-for-nyx-bar) | Aura doesn't account for Nyx Bar | apps/assistant.md |
| [NYX-APP-BACKUP-002](apps/backup.md#nyx-app-backup-002-offline-disk-recovery-is-offered-on-nyxos-but-cant-work-there) | Offline disk recovery is offered on NyxOS but can't work there | apps/backup.md |
| [NYX-APP-BACKUP-003](apps/backup.md#nyx-app-backup-003-restore-and-scheduling-were-never-qualified-on-nyxos-and-the-smoke-tests-are-manual) | Restore and scheduling were never qualified on NyxOS, and the smoke tests are manual | apps/backup.md |
| [NYX-APP-BIOMETRICS-001](apps/biometrics.md#nyx-app-biometrics-001-settings-sign-in-page-offers-arch-only-actions-on-nyxos) | Settings' Sign-in page offers Arch-only actions on NyxOS | apps/biometrics.md |
| [NYX-APP-BIOMETRICS-002](apps/biometrics.md#nyx-app-biometrics-002-admin-prompt-and-sudo-make-the-password-wait-behind-a-fingerprintface-attempt) | Admin prompt and sudo make the password wait behind a fingerprint/face attempt | apps/biometrics.md |
| [NYX-APP-CALCULATOR-001](apps/calculator.md#nyx-app-calculator-001-no-license-file-although-the-package-is-declared-mit) | No LICENSE file although the package is declared MIT | apps/calculator.md |
| [NYX-APP-CALENDAR-001](apps/calendar.md#nyx-app-calendar-001-googlemicrosoft-calendars-need-a-self-registered-oauth-client) | Google/Microsoft calendars need a self-registered OAuth client | apps/calendar.md |
| [NYX-APP-CALENDAR-002](apps/calendar.md#nyx-app-calendar-002-action-manifests-d-bus-activation-may-not-work-for-per-user-installs) | Action manifest's D-Bus activation may not work for per-user installs | apps/calendar.md |
| [NYX-APP-CAPTURE-001](apps/capture.md#nyx-app-capture-001-webcam-overlay-relies-on-omarchys-window-rules-which-nyxos-doesnt-have) | Webcam overlay relies on Omarchy's window rules, which NyxOS doesn't have | apps/capture.md |
| [NYX-APP-CHAT-001](apps/chat.md#nyx-app-chat-001-voice-input-and-read-aloud-use-private-whispercpppiper-runners-that-nyxos-doesnt-ship) | Voice input and read-aloud use private whisper.cpp/Piper runners that NyxOS doesn't ship | apps/chat.md |
| [NYX-APP-CLIPBOARD-001](apps/clipboard.md#nyx-app-clipboard-001-clipboard-settings-retention-exclusions-codes-unreachable-on-nyxos) | Clipboard settings (retention, exclusions, codes) unreachable on NyxOS | apps/clipboard.md |
| [NYX-APP-CLOUD-001](apps/cloud.md#nyx-app-cloud-001-cloud-credentials-stored-reversibly-in-rcloneconf) | Cloud credentials stored reversibly in rclone.conf | apps/cloud.md |
| [NYX-APP-CONTACTS-001](apps/contacts.md#nyx-app-contacts-001-online-address-books-depend-on-developer-grade-account-setup) | Online address books depend on developer-grade account setup | apps/contacts.md |
| [NYX-APP-CONTAINERS-002](apps/containers.md#nyx-app-containers-002-diagnostics-fix-runs-arch-commands-through-pkexec-on-nyxos) | Diagnostics "Fix" runs Arch commands through pkexec on NyxOS | apps/containers.md |
| [NYX-APP-CONTAINERS-003](apps/containers.md#nyx-app-containers-003-root-equivalent-group-access-isnt-explained) | Root-equivalent group access isn't explained | apps/containers.md |
| [NYX-APP-FILES-001](apps/files.md#nyx-app-files-001-file-safety-tests-are-skipped-in-the-package-and-the-repositorys-ci-runs-no-tests) | File-safety tests are skipped in the package and the repository's CI runs no tests | apps/files.md |
| [NYX-APP-GIT-001](apps/git.md#nyx-app-git-001-pushfetch-over-authenticated-https-or-passphrase-ssh-needs-setup-nyxos-doesnt-provide) | Push/fetch over authenticated HTTPS or passphrase SSH needs setup NyxOS doesn't provide | apps/git.md |
| [NYX-APP-GREETER-001](apps/greeter.md#nyx-app-greeter-001-when-greetds-connection-fails-the-login-screen-is-a-dead-end) | When greetd's connection fails, the login screen is a dead end | apps/greeter.md |
| [NYX-APP-GREETER-002](apps/greeter.md#nyx-app-greeter-002-no-keyboard-layout-indicator-or-caps-lock-warning-at-the-password-field) | No keyboard layout indicator or Caps Lock warning at the password field | apps/greeter.md |
| [NYX-APP-GREETER-003](apps/greeter.md#nyx-app-greeter-003-no-screen-reader-at-the-login-screen) | No screen reader at the login screen | apps/greeter.md |
| [NYX-APP-INSTALLER-002](apps/installer.md#nyx-app-installer-002-a-failed-install-beside-windows-leaves-its-partitions-behind-and-the-only-remaining-choice-erases-windows) | A failed install beside Windows leaves its partitions behind, and the only remaining choice erases Windows | apps/installer.md |
| [NYX-APP-INSTALLER-003](apps/installer.md#nyx-app-installer-003-no-bitlocker-or-secure-boot-guidance-for-dual-boot-and-docs-claim-tpm2-and-secure-boot-setup-the-installer-doesnt-do) | No BitLocker or Secure Boot guidance for dual boot, and docs claim TPM2 and Secure Boot setup the installer doesn't do | apps/installer.md |
| [NYX-APP-LYRA-001](apps/lyra.md#nyx-app-lyra-001-built-on-youtube-musics-private-web-api-and-a-hidden-web-player) | Built on YouTube Music's private web API and a hidden web player | apps/lyra.md |
| [NYX-APP-LYRA-002](apps/lyra.md#nyx-app-lyra-002-no-ci-for-a-welcome-tier-app-marked-in-progress) | No CI for a Welcome-tier app marked "In progress" | apps/lyra.md |
| [NYX-APP-LYRA-003](apps/lyra.md#nyx-app-lyra-003-high-memory-use-from-the-embedded-web-player) | High memory use from the embedded web player | apps/lyra.md |
| [NYX-APP-MAIL-002](apps/mail.md#nyx-app-mail-002-glimpse-plugin-from-a-per-user-install-is-not-linked-where-glimpse-looks) | Glimpse plugin from a per-user install is not linked where Glimpse looks | apps/mail.md |
| [NYX-APP-MAPS-001](apps/maps.md#nyx-app-maps-001-directions-depend-on-the-public-osrm-demo-server) | Directions depend on the public OSRM demo server | apps/maps.md |
| [NYX-APP-MAPS-002](apps/maps.md#nyx-app-maps-002-per-user-installs-have-no-geoclue-so-my-location-falls-back-to-third-party-ip-lookup) | Per-user installs have no GeoClue, so "my location" falls back to third-party IP lookup | apps/maps.md |
| [NYX-APP-NOTEPAD-001](apps/notepad.md#nyx-app-notepad-001-saving-a-non-utf-8-file-replaces-its-non-ascii-bytes-for-good) | Saving a non-UTF-8 file replaces its non-ASCII bytes for good | apps/notepad.md |
| [NYX-APP-NOTES-001](apps/notes.md#nyx-app-notes-001-notes-builds-two-nyx-core-revisions-and-an-older-ai-core-client) | Notes builds two nyx-core revisions and an older AI Core client | apps/notes.md |
| [NYX-APP-PASSWORDS-002](apps/passwords.md#nyx-app-passwords-002-package-metadata-says-mit-the-app-is-gpl-30-only) | Package metadata says MIT; the app is GPL-3.0-only | apps/passwords.md |
| [NYX-APP-PDF-001](apps/pdf.md#nyx-app-pdf-001-edit-text-leaves-the-original-words-in-the-file) | "Edit text" leaves the original words in the file | apps/pdf.md |
| [NYX-APP-PHOTOS-001](apps/photos.md#nyx-app-photos-001-set-as-background-is-omarchy-only-and-hidden-on-nyxos) | "Set as background" is Omarchy-only and hidden on NyxOS | apps/photos.md |
| [NYX-APP-PHOTOS-002](apps/photos.md#nyx-app-photos-002-saved-edits-drop-exif-date-taken-gps-camera) | Saved edits drop EXIF (date taken, GPS, camera) | apps/photos.md |
| [NYX-APP-PULSE-001](apps/pulse.md#nyx-app-pulse-001-project-telegram-api-idhash-compiled-into-the-source-as-defaults) | Project Telegram API id/hash compiled into the source as defaults | apps/pulse.md |
| [NYX-APP-PULSE-002](apps/pulse.md#nyx-app-pulse-002-calls-the-advertised-feature-are-unverified-against-other-telegram-clients) | Calls, the advertised feature, are unverified against other Telegram clients | apps/pulse.md |
| [NYX-APP-REMINDERS-001](apps/reminders.md#nyx-app-reminders-001-account-sync-rests-on-an-unverified-online-accounts-preview-and-main-still-says-not-merge-ready) | Account sync rests on an unverified Online Accounts preview, and main still says "not merge-ready" | apps/reminders.md |
| [NYX-APP-SETTINGS-001](apps/settings.md#nyx-app-settings-001-vpn-provider-install-and-openvpn-import-run-omarchypacman-commands-on-nyxos) | VPN provider install and OpenVPN import run Omarchy/pacman commands on NyxOS | apps/settings.md |
| [NYX-APP-THEATER-001](apps/theater.md#nyx-app-theater-001-no-mpris-player-so-media-keys-and-the-bar-cant-control-playback) | No MPRIS player, so media keys and the bar can't control playback | apps/theater.md |
| [NYX-APP-TORRENTS-001](apps/torrents.md#nyx-app-torrents-001-search-plugins-run-arbitrary-python-from-any-url-without-a-warning) | Search plugins run arbitrary Python from any URL without a warning | apps/torrents.md |
| [NYX-APP-WELCOME-001](apps/welcome.md#nyx-app-welcome-001-setups-apply-path-has-almost-no-tests-and-no-ci) | Setup's apply path has almost no tests and no CI | apps/welcome.md |
| [NYX-ARCH-001](architecture.md#nyx-arch-001-shell-components-keep-their-own-hyprland-watchers-and-window-models) | Shell components keep their own Hyprland watchers and window models | architecture.md |
| [NYX-ARCH-002](architecture.md#nyx-arch-002-most-shell-surfaces-bypass-shell-cores-overlay-registry) | Most shell surfaces bypass Shell Core's overlay registry | architecture.md |
| [NYX-CI-004](packaging-ci.md#nyx-ci-004-app-ci-mostly-never-runs-16-core-repositories-have-none) | App CI mostly never runs; 16 core repositories have none | packaging-ci.md |
| [NYX-CI-005](packaging-ci.md#nyx-ci-005-the-installer-image-isnt-built-by-ci-and-the-release-has-no-artifacts-or-provenance) | The installer image isn't built by CI and the release has no artifacts or provenance | packaging-ci.md |
| [NYX-CONN-001](infrastructure.md#nyx-conn-001-nyx-connect-opens-port-12100-and-advertises-the-machine-on-every-network-by-default) | Nyx Connect opens port 12100 and advertises the machine on every network by default | infrastructure.md |
| [NYX-DEP-001](dependencies.md#nyx-dep-001-no-automated-dependency-monitoring-for-rust-crates-or-flake-inputs) | No automated dependency monitoring for Rust crates or flake inputs | dependencies.md |
| [NYX-DEP-003](dependencies.md#nyx-dep-003-nine-packages-pinned-ahead-of-nixpkgs-each-maintained-by-hand) | Nine packages pinned ahead of nixpkgs, each maintained by hand | dependencies.md |
| [NYX-DEP-004](dependencies.md#nyx-dep-004-forks-and-patch-series-with-manual-single-person-upkeep) | Forks and patch series with manual, single-person upkeep | dependencies.md |
| [NYX-DOC-001](docs-review.md#nyx-doc-001-no-user-documentation-for-installing-requirements-troubleshooting-or-limitations) | No user documentation for installing, requirements, troubleshooting or limitations | docs-review.md |
| [NYX-DOC-002](docs-review.md#nyx-doc-002-28-readmes-present-the-apps-as-omarchy-software-44-give-only-arch-install-steps) | 28 READMEs present the apps as Omarchy software, 44 give only Arch install steps | docs-review.md |
| [NYX-HYPR-001](hyprland-patches.md#nyx-hypr-001-fullscreen-own-workspace-is-on-by-default-but-unverified-on-0572) | Fullscreen-own-workspace is on by default but unverified on 0.57.2 | hyprland-patches.md |
| [NYX-HYPR-002](hyprland-patches.md#nyx-hypr-002-fullscreen-workspaces-are-invisible-to-the-dock-and-bar-models) | Fullscreen workspaces are invisible to the Dock and Bar models | hyprland-patches.md |
| [NYX-HYPR-003](hyprland-patches.md#nyx-hypr-003-virtual-monitors-exposed-in-settings-despite-an-unexplained-confirm-timeout-hang) | Virtual monitors exposed in Settings despite an unexplained confirm-timeout hang | hyprland-patches.md |
| [NYX-HYPR-004](hyprland-patches.md#nyx-hypr-004-no-automated-test-of-any-compositor-patch-runs-anywhere) | No automated test of any compositor patch runs anywhere | hyprland-patches.md |
| [NYX-PKG-001](packaging-ci.md#nyx-pkg-001-package-test-runs-are-narrowed-and-files-security-tests-run-nowhere) | Package test runs are narrowed, and Files' security tests run nowhere | packaging-ci.md |
| [NYX-PKG-002](packaging-ci.md#nyx-pkg-002-shared-crates-drift-apps-build-ten-nyx-core-and-seven-nyx-design-revisions) | Shared crates drift: apps build ten nyx-core and seven nyx-design revisions | packaging-ci.md |
| [NYX-PKG-009](packaging-ci.md#nyx-pkg-009-apps-installed-per-user-have-no-d-bus-activation-or-nyx-actions-until-something-else-wires-them) | Apps installed per user have no D-Bus activation or `nyx` actions until something else wires them | packaging-ci.md |
| [NYX-PRIV-001](privacy.md#nyx-priv-001-any-wayland-client-can-capture-the-screen-silently-and-the-indicator-cant-see-it) | Any Wayland client can capture the screen silently, and the indicator can't see it | privacy.md |
| [NYX-PRIV-002](privacy.md#nyx-priv-002-the-assistant-listens-all-the-time-once-enabled-though-its-default-mode-is-called-push-to-talk) | The Assistant listens all the time once enabled, though its default mode is called push-to-talk | privacy.md |
| [NYX-REL-002](reliability.md#nyx-rel-002-an-interrupted-system-manager-change-leaves-the-unapplied-change-in-the-overrides-layer) | An interrupted System Manager change leaves the unapplied change in the overrides layer | reliability.md |
| [NYX-REL-003](reliability.md#nyx-rel-003-a-monitor-connected-while-the-session-runs-gets-no-bar-or-dock) | A monitor connected while the session runs gets no bar or dock | reliability.md |
| [NYX-SEC-001](security.md#nyx-sec-001-ai-cores-openai-endpoint-has-no-authentication-and-no-hostorigin-check) | AI Core's OpenAI endpoint has no authentication and no Host/Origin check | security.md |
| [NYX-SEC-002](security.md#nyx-sec-002-caller-identity-by-program-path-is-spoofable-the-root-key-service-trusts-localbin) | Caller identity by program path is spoofable; the root key service trusts `~/.local/bin` | security.md |
| [NYX-SEC-003](security.md#nyx-sec-003-nyx-connect-opens-port-12100-on-every-network-and-interface-by-default) | Nyx Connect opens port 12100 on every network and interface by default | security.md |
| [NYX-SEC-004](security.md#nyx-sec-004-every-primary-user-is-in-the-input-group) | Every primary user is in the `input` group | security.md |
| [NYX-SEC-005](security.md#nyx-sec-005-the-recovery-boot-entry-is-a-passwordless-root-console) | The Recovery boot entry is a passwordless root console | security.md |
| [NYX-SEC-006](security.md#nyx-sec-006-webcam-face-matching-gaze-can-be-a-sufficient-factor-for-sudo-polkit-login-and-unlock) | Webcam face matching (Gaze) can be a sufficient factor for sudo, polkit, login and unlock | security.md |
| [NYX-SEC-007](security.md#nyx-sec-007-voice-models-are-downloaded-at-runtime-without-integrity-checks) | Voice models are downloaded at runtime without integrity checks | security.md |
| [NYX-SEC-008](security.md#nyx-sec-008-no-release-signing-user-level-apps-update-automatically-from-the-channel-branch) | No release signing; user-level apps update automatically from the channel branch | security.md |
| [NYX-SHELL-001](shell.md#nyx-shell-001-one-quickshell-process-is-the-whole-visible-shell-with-no-fallback-after-its-start-limit) | One Quickshell process is the whole visible shell, with no fallback after its start limit | shell.md |
| [NYX-SHELL-002](shell.md#nyx-shell-002-stale-overlay-state-while-shell-core-is-away-traps-or-disables-glimpse) | Stale overlay state while Shell Core is away traps or disables Glimpse | shell.md |
| [NYX-SHELL-005](shell.md#nyx-shell-005-keyboard-and-screen-reader-paths-missing-in-most-shell-qml) | Keyboard and screen-reader paths missing in most shell QML | shell.md |
| [NYX-SYS-001](infrastructure.md#nyx-sys-001-the-recovery-boot-entry-is-a-passwordless-root-console) | The recovery boot entry is a passwordless root console | infrastructure.md |
| [NYX-THEME-001](infrastructure.md#nyx-theme-001-apps-build-seven-different-copies-of-the-theme-engine-so-the-default-theme-looks-different-in-apps-and-the-shell) | Apps build seven different copies of the theme engine, so the default theme looks different in apps and the shell | infrastructure.md |
| [NYX-THEME-002](infrastructure.md#nyx-theme-002-the-default-catppuccin-mocha-isnt-catppuccins-palette-and-its-secondary-text-fails-wcag-aa) | The default Catppuccin Mocha isn't Catppuccin's palette and its secondary text fails WCAG AA | infrastructure.md |
| [NYX-UPD-001](infrastructure.md#nyx-upd-001-system-update-plans-dont-show-what-will-change-before-confirmation) | System update plans don't show what will change before confirmation | infrastructure.md |
| [NYX-VOICE-001](infrastructure.md#nyx-voice-001-dictation-isnt-wired-on-nyxos-though-settings-and-docs-say-it-is) | Dictation isn't wired on NyxOS, though Settings and docs say it is | infrastructure.md |
| [NYX-VOICE-002](infrastructure.md#nyx-voice-002-speech-models-are-downloaded-without-integrity-checks-one-from-a-moving-branch) | Speech models are downloaded without integrity checks, one from a moving branch | infrastructure.md |

## P3

| ID | Title | Report |
| --- | --- | --- |
| [NYX-A11Y-003](ux-accessibility.md#nyx-a11y-003-four-store-category-buttons-have-no-accessible-name) | Four Store category buttons have no accessible name | ux-accessibility.md |
| [NYX-APP-ACTIVITY-001](apps/activity.md#nyx-app-activity-001-startup-page-shows-an-empty-omarchy-section-and-count-on-nyxos) | Startup page shows an empty Omarchy section and count on NyxOS | apps/activity.md |
| [NYX-APP-AGENTS-002](apps/agents.md#nyx-app-agents-002-no-ci-and-an-inaccessible-terminal) | No CI and an inaccessible terminal | apps/agents.md |
| [NYX-APP-ARCHIVE-002](apps/archive.md#nyx-app-archive-002-extraction-path-safety-rests-entirely-on-7-zip) | Extraction path safety rests entirely on 7-Zip | apps/archive.md |
| [NYX-APP-ARCHIVE-003](apps/archive.md#nyx-app-archive-003-readme-describes-omarchy-and-a-pacman-install) | README describes Omarchy and a pacman install | apps/archive.md |
| [NYX-APP-ASSISTANT-006](apps/assistant.md#nyx-app-assistant-006-omarchy-centric-readme-docs-and-system-prompt) | Omarchy-centric README, docs and system prompt | apps/assistant.md |
| [NYX-APP-ASSISTANT-007](apps/assistant.md#nyx-app-assistant-007-shared-crate-pin-drift-uncommitted-bump-and-thin-packaged-tests) | Shared-crate pin drift, uncommitted bump and thin packaged tests | apps/assistant.md |
| [NYX-APP-ASSISTANT-008](apps/assistant.md#nyx-app-assistant-008-pacman-based-admin-tools-stay-in-the-tool-set-on-nyxos) | pacman-based admin tools stay in the tool set on NyxOS | apps/assistant.md |
| [NYX-APP-BACKUP-004](apps/backup.md#nyx-app-backup-004-user-migration-only-works-between-archomarchy-machines) | User migration only works between Arch/Omarchy machines | apps/backup.md |
| [NYX-APP-BIOMETRICS-003](apps/biometrics.md#nyx-app-biometrics-003-no-desktop-path-to-turn-biometrics-on) | No desktop path to turn biometrics on | apps/biometrics.md |
| [NYX-APP-BIOMETRICS-004](apps/biometrics.md#nyx-app-biometrics-004-biometrics-trusted-bin-line-is-overwritten-by-the-main-module) | Biometrics' trusted-bin line is overwritten by the main module | apps/biometrics.md |
| [NYX-APP-CALCULATOR-002](apps/calculator.md#nyx-app-calculator-002-graph-view-ignores-the-theme-always-dark) | Graph view ignores the theme (always dark) | apps/calculator.md |
| [NYX-APP-CALCULATOR-003](apps/calculator.md#nyx-app-calculator-003-no-check-ci-readme-describes-omarchy) | No check CI; README describes Omarchy | apps/calculator.md |
| [NYX-APP-CALENDAR-003](apps/calendar.md#nyx-app-calendar-003-readme-on-main-says-the-branch-is-not-merge-ready) | README on `main` says the branch is not merge-ready | apps/calendar.md |
| [NYX-APP-CAPTURE-002](apps/capture.md#nyx-app-capture-002-no-action-manifest-captures-commands-arent-reachable-from-nyx-glimpse-or-the-assistant-unless-it-is-open) | No action manifest; Capture's commands aren't reachable from `nyx`, Glimpse or the Assistant unless it is open | apps/capture.md |
| [NYX-APP-CHAT-002](apps/chat.md#nyx-app-chat-002-web-tools-on-by-default-search-api-keys-kept-in-plain-settings-file) | Web tools on by default; search API keys kept in plain settings file | apps/chat.md |
| [NYX-APP-CHAT-003](apps/chat.md#nyx-app-chat-003-readme-and-catalog-text-out-of-date) | README and catalog text out of date | apps/chat.md |
| [NYX-APP-CLIPBOARD-002](apps/clipboard.md#nyx-app-clipboard-002-no-ci-workflow) | No CI workflow | apps/clipboard.md |
| [NYX-APP-CLOUD-002](apps/cloud.md#nyx-app-cloud-002-store-item-has-no-visible-app-and-tests-barely-run) | Store item has no visible app, and tests barely run | apps/cloud.md |
| [NYX-APP-CONTACTS-002](apps/contacts.md#nyx-app-contacts-002-readme-says-online-books-come-through-evolution-data-server) | README says online books come through Evolution Data Server | apps/contacts.md |
| [NYX-APP-CONTACTS-003](apps/contacts.md#nyx-app-contacts-003-assistant-tools-without-an-installed-action-manifest) | Assistant tools without an installed action manifest | apps/contacts.md |
| [NYX-APP-CONTAINERS-004](apps/containers.md#nyx-app-containers-004-hard-coded-developer-username-fallback) | Hard-coded developer username fallback | apps/containers.md |
| [NYX-APP-CONTAINERS-005](apps/containers.md#nyx-app-containers-005-readme-and-source-header-are-archomarchy-specific-and-stale) | README and source header are Arch/Omarchy-specific and stale | apps/containers.md |
| [NYX-APP-FILES-002](apps/files.md#nyx-app-files-002-omarchy-specific-text-reachable-on-nyxos) | Omarchy-specific text reachable on NyxOS | apps/files.md |
| [NYX-APP-FONTS-001](apps/fonts.md#nyx-app-fonts-001-packaged-but-not-offered-anywhere) | Packaged but not offered anywhere | apps/fonts.md |
| [NYX-APP-FONTS-002](apps/fonts.md#nyx-app-fonts-002-google-fonts-catalog-relies-on-undocumented-endpoints) | Google Fonts catalog relies on undocumented endpoints | apps/fonts.md |
| [NYX-APP-FONTS-003](apps/fonts.md#nyx-app-fonts-003-no-action-manifest-readme-omarchy-first) | No action manifest; README Omarchy-first | apps/fonts.md |
| [NYX-APP-GIT-002](apps/git.md#nyx-app-git-002-omarchy-wording-in-an-editor-error-message) | Omarchy wording in an editor error message | apps/git.md |
| [NYX-APP-GLIMPSE-001](apps/glimpse.md#nyx-app-glimpse-001-a-search-hit-without-a-path-panics-the-search) | A search hit without a path panics the search | apps/glimpse.md |
| [NYX-APP-GLIMPSE-002](apps/glimpse.md#nyx-app-glimpse-002-integration-tests-are-excluded-from-the-package-build) | Integration tests are excluded from the package build | apps/glimpse.md |
| [NYX-APP-HOME-001](apps/home.md#nyx-app-home-001-no-ci-check-workflow) | No CI check workflow | apps/home.md |
| [NYX-APP-HOME-002](apps/home.md#nyx-app-home-002-plain-http-home-assistant-addresses-accepted-without-a-warning) | Plain-HTTP Home Assistant addresses accepted without a warning | apps/home.md |
| [NYX-APP-HOME-003](apps/home.md#nyx-app-home-003-implementation-plan-says-assistant-integration-is-pending) | Implementation plan says Assistant integration is pending | apps/home.md |
| [NYX-APP-INSTALLER-004](apps/installer.md#nyx-app-installer-004-sizes-beside-another-system-assume-512-byte-sectors) | Sizes beside another system assume 512-byte sectors | apps/installer.md |
| [NYX-APP-LYRA-004](apps/lyra.md#nyx-app-lyra-004-google-session-cookies-are-stored-unencrypted) | Google session cookies are stored unencrypted | apps/lyra.md |
| [NYX-APP-MAIL-003](apps/mail.md#nyx-app-mail-003-architecture-doc-still-describes-goa) | Architecture doc still describes GOA | apps/mail.md |
| [NYX-APP-MAPS-003](apps/maps.md#nyx-app-maps-003-no-ci-checks-thin-tests-arch-only-readme) | No CI checks, thin tests, Arch-only README | apps/maps.md |
| [NYX-APP-MEDIA-PLAYER-001](apps/media-player.md#nyx-app-media-player-001-no-action-manifest-nyx-cli-glimpse-and-assistant-cant-reach-it-when-closed) | No action manifest; nyx CLI, Glimpse and Assistant can't reach it when closed | apps/media-player.md |
| [NYX-APP-MEDIA-PLAYER-002](apps/media-player.md#nyx-app-media-player-002-catalog-says-music-files-but-only-video-types-are-registered-no-default-video-handler-on-nyxos) | Catalog says "music files" but only video types are registered; no default video handler on NyxOS | apps/media-player.md |
| [NYX-APP-MEDIA-PLAYER-003](apps/media-player.md#nyx-app-media-player-003-tmdb-api-key-kept-in-plain-settings) | TMDB API key kept in plain settings | apps/media-player.md |
| [NYX-APP-MEDIA-PLAYER-004](apps/media-player.md#nyx-app-media-player-004-documentation-describes-an-omarchy-app) | Documentation describes an Omarchy app | apps/media-player.md |
| [NYX-APP-MUSIC-001](apps/music.md#nyx-app-music-001-documentation-and-crate-metadata-describe-an-omarchy-app) | Documentation and crate metadata describe an Omarchy app | apps/music.md |
| [NYX-APP-MUSIC-002](apps/music.md#nyx-app-music-002-icon-only-controls-named-only-through-tooltips) | Icon-only controls named only through tooltips | apps/music.md |
| [NYX-APP-NEWS-001](apps/news.md#nyx-app-news-001-reserved-features-shown-but-off) | Reserved features shown but off | apps/news.md |
| [NYX-APP-NEWS-002](apps/news.md#nyx-app-news-002-readme-describes-omarchy) | README describes Omarchy | apps/news.md |
| [NYX-APP-NOTEPAD-002](apps/notepad.md#nyx-app-notepad-002-a-closed-tabs-unsaved-text-is-lost-if-the-app-quits-before-undo) | A closed tab's unsaved text is lost if the app quits before Undo | apps/notepad.md |
| [NYX-APP-NOTEPAD-003](apps/notepad.md#nyx-app-notepad-003-readme-describes-omarchy-and-a-pacman-install) | README describes Omarchy and a pacman install | apps/notepad.md |
| [NYX-APP-NOTES-002](apps/notes.md#nyx-app-notes-002-planmd-and-readme-carry-stale-pins-and-arch-instructions) | PLAN.md and README carry stale pins and Arch instructions | apps/notes.md |
| [NYX-APP-OFFICE-002](apps/office.md#nyx-app-office-002-icon-only-buttons-have-tooltips-but-no-accessible-names) | Icon-only buttons have tooltips but no accessible names | apps/office.md |
| [NYX-APP-OFFICE-003](apps/office.md#nyx-app-office-003-readme-describes-omarchy) | README describes Omarchy | apps/office.md |
| [NYX-APP-PASSWORDS-003](apps/passwords.md#nyx-app-passwords-003-screen-lock-auto-lock-depends-on-the-units-hyprland-environment) | Screen-lock auto-lock depends on the unit's Hyprland environment | apps/passwords.md |
| [NYX-APP-PASSWORDS-004](apps/passwords.md#nyx-app-passwords-004-stale-references-in-docs-and-the-recipe) | Stale references in docs and the recipe | apps/passwords.md |
| [NYX-APP-PDF-002](apps/pdf.md#nyx-app-pdf-002-save-isnt-fsynced-and-resets-file-permissions) | Save isn't fsynced and resets file permissions | apps/pdf.md |
| [NYX-APP-PDF-003](apps/pdf.md#nyx-app-pdf-003-readme-describes-omarchy) | README describes Omarchy | apps/pdf.md |
| [NYX-APP-PHOTOS-003](apps/photos.md#nyx-app-photos-003-readme-describes-omarchy) | README describes Omarchy | apps/photos.md |
| [NYX-APP-PULSE-003](apps/pulse.md#nyx-app-pulse-003-omarchy-linux-device-name-sent-to-telegram) | "Omarchy Linux" device name sent to Telegram | apps/pulse.md |
| [NYX-APP-PULSE-004](apps/pulse.md#nyx-app-pulse-004-network-facing-call-engine-is-a-prebuilt-binary-nyxos-cant-patch) | Network-facing call engine is a prebuilt binary NyxOS can't patch | apps/pulse.md |
| [NYX-APP-PULSE-005](apps/pulse.md#nyx-app-pulse-005-design-docs-contradict-the-implementation-unwraps-on-runtime-data) | Design docs contradict the implementation; unwraps on runtime data | apps/pulse.md |
| [NYX-APP-REMINDERS-002](apps/reminders.md#nyx-app-reminders-002-docs-contradict-the-backend) | Docs contradict the backend | apps/reminders.md |
| [NYX-APP-SETTINGS-002](apps/settings.md#nyx-app-settings-002-omarchy-wording-and-near-empty-pages-on-nyxos) | Omarchy wording and near-empty pages on NyxOS | apps/settings.md |
| [NYX-APP-SETTINGS-003](apps/settings.md#nyx-app-settings-003-nyxos-build-not-tested-in-ci-package-runs-only-the-binarys-tests) | NyxOS build not tested in CI; package runs only the binary's tests | apps/settings.md |
| [NYX-APP-SHARE-002](apps/share.md#nyx-app-share-002-share-extensions-are-unavailable-on-nyxos) | Share extensions are unavailable on NyxOS | apps/share.md |
| [NYX-APP-STORE-001](apps/store.md#nyx-app-store-001-stores-launcher-entry-and-readme-describe-the-omarchyarch-store) | Store's launcher entry and README describe the Omarchy/Arch store | apps/store.md |
| [NYX-APP-STORE-002](apps/store.md#nyx-app-store-002-a-failed-flathub-or-nix-profile-step-after-a-system-change-doesnt-say-the-system-part-was-applied) | A failed Flathub or Nix profile step after a system change doesn't say the system part was applied | apps/store.md |
| [NYX-APP-THEATER-002](apps/theater.md#nyx-app-theater-002-no-action-manifest-legacy-control-api) | No action manifest (legacy control API) | apps/theater.md |
| [NYX-APP-THEATER-003](apps/theater.md#nyx-app-theater-003-registers-local-video-mime-types-competing-with-media-player) | Registers local video MIME types, competing with Media Player | apps/theater.md |
| [NYX-APP-TORRENTS-002](apps/torrents.md#nyx-app-torrents-002-listening-port-blocked-by-the-nyxos-firewall-upnp-on-by-default) | Listening port blocked by the NyxOS firewall; UPnP on by default | apps/torrents.md |
| [NYX-APP-TORRENTS-003](apps/torrents.md#nyx-app-torrents-003-no-action-manifest-docs-and-hints-are-omarchyarch-oriented) | No action manifest; docs and hints are Omarchy/Arch-oriented | apps/torrents.md |
| [NYX-APP-TRANSFER-001](apps/transfer.md#nyx-app-transfer-001-store-description-misstates-the-app) | Store description misstates the app | apps/transfer.md |
| [NYX-APP-TRANSFER-002](apps/transfer.md#nyx-app-transfer-002-no-license-file-and-no-ci-test-run) | No LICENSE file and no CI test run | apps/transfer.md |
| [NYX-APP-WEATHER-001](apps/weather.md#nyx-app-weather-001-floating-window-preference-writes-an-omarchy-rule-and-reloads-hyprland-on-nyxos) | Floating-window preference writes an Omarchy rule and reloads Hyprland on NyxOS | apps/weather.md |
| [NYX-APP-WEATHER-002](apps/weather.md#nyx-app-weather-002-omarchy-and-waybar-wording-in-readme-and-entry-point) | Omarchy and Waybar wording in README and entry point | apps/weather.md |
| [NYX-APP-WELCOME-002](apps/welcome.md#nyx-app-welcome-002-welcome-can-run-twice-and-be-closed-mid-apply-without-warning) | Welcome can run twice and be closed mid-apply without warning | apps/welcome.md |
| [NYX-ARCH-003](architecture.md#nyx-arch-003-component-registry-and-health-reflect-almost-none-of-the-shell) | Component registry and health reflect almost none of the shell | architecture.md |
| [NYX-ARCH-004](architecture.md#nyx-arch-004-no-shipped-shortcut-goes-through-shell-cores-action-router) | No shipped shortcut goes through Shell Core's action router | architecture.md |
| [NYX-ARCH-005](architecture.md#nyx-arch-005-five-ipc-mechanisms-inside-the-shell) | Five IPC mechanisms inside the shell | architecture.md |
| [NYX-ARCH-006](architecture.md#nyx-arch-006-desktop-widgets-arent-enabled-on-any-nyxos-configuration) | Desktop Widgets aren't enabled on any NyxOS configuration | architecture.md |
| [NYX-ARCH-007](architecture.md#nyx-arch-007-notification-center-and-switcher-still-run-their-gtk-front-ends-on-nyxos) | Notification Center and Switcher still run their GTK front ends on NyxOS | architecture.md |
| [NYX-ARCH-008](architecture.md#nyx-arch-008-shell-documentation-describes-an-older-nyxos-arrangement) | Shell documentation describes an older NyxOS arrangement | architecture.md |
| [NYX-ARCH-009](architecture.md#nyx-arch-009-omarchy-leftovers-in-code-that-runs-on-nyxos) | Omarchy leftovers in code that runs on NyxOS | architecture.md |
| [NYX-ARCH-010](architecture.md#nyx-arch-010-component-backends-accept-any-same-user-client) | Component backends accept any same-user client | architecture.md |
| [NYX-CI-006](packaging-ci.md#nyx-ci-006-proposed-updates-sit-unreviewed) | Proposed updates sit unreviewed | packaging-ci.md |
| [NYX-CI-007](packaging-ci.md#nyx-ci-007-dev-vm-packages-copies-the-vms-lock-back-over-the-checkout) | `dev-vm packages` copies the VM's lock back over the checkout | packaging-ci.md |
| [NYX-DEP-002](dependencies.md#nyx-dep-002-six-unmaintained-or-deprecated-crates-in-shipped-apps) | Six unmaintained or deprecated crates in shipped apps | dependencies.md |
| [NYX-DEP-005](dependencies.md#nyx-dep-005-duplicated-crate-versions-and-a-second-nixpkgs-inflate-builds-and-the-closure) | Duplicated crate versions and a second nixpkgs inflate builds and the closure | dependencies.md |
| [NYX-DOC-003](docs-review.md#nyx-doc-003-the-distributions-own-docs-are-stale) | The distribution's own docs are stale | docs-review.md |
| [NYX-DOC-004](docs-review.md#nyx-doc-004-process-docs-promise-ci-gates-and-behaviour-that-dont-exist) | Process docs promise CI gates and behaviour that don't exist | docs-review.md |
| [NYX-DOC-005](docs-review.md#nyx-doc-005-no-nyxos-level-architecture-or-security-model) | No NyxOS-level architecture or security model | docs-review.md |
| [NYX-HYPR-005](hyprland-patches.md#nyx-hypr-005-patch-series-documentation-has-drifted-from-the-series) | Patch-series documentation has drifted from the series | hyprland-patches.md |
| [NYX-HYPR-006](hyprland-patches.md#nyx-hypr-006-hyprland-version-and-patch-series-are-declared-separately-and-nix-applies-patches-with-fuzz) | Hyprland version and patch series are declared separately, and Nix applies patches with fuzz | hyprland-patches.md |
| [NYX-HYPR-007](hyprland-patches.md#nyx-hypr-007-stale-series-folders-and-updatesh-can-silently-fall-back-to-an-older-series) | Stale series folders, and update.sh can silently fall back to an older series | hyprland-patches.md |
| [NYX-HYPR-008](hyprland-patches.md#nyx-hypr-008-layer-slide-render-hook-runs-for-every-top-layer-on-every-frame) | Layer-slide render hook runs for every top layer on every frame | hyprland-patches.md |
| [NYX-HYPR-009](hyprland-patches.md#nyx-hypr-009-the-screen-sharing-portal-isnt-the-one-the-hyprland-flake-pins) | The screen-sharing portal isn't the one the Hyprland flake pins | hyprland-patches.md |
| [NYX-INST-003](installation.md#nyx-inst-003-the-machines-lock-records-the-installers-mnt-overrides-path) | The machine's lock records the installer's `/mnt` overrides path | installation.md |
| [NYX-PERF-001](performance.md#nyx-perf-001-every-gtk-app-costs-at-least-130-mb-and-the-shell-300-mb-in-one-process) | Every GTK app costs at least 130 MB, and the shell 300 MB in one process | performance.md |
| [NYX-PERF-002](performance.md#nyx-perf-002-ai-cores-statistics-ignore-requests-made-through-its-openai-endpoint) | AI Core's statistics ignore requests made through its OpenAI endpoint | performance.md |
| [NYX-PKG-003](packaging-ci.md#nyx-pkg-003-license-metadata-defaulted-to-mit-six-repositories-have-no-license-file) | License metadata defaulted to MIT; six repositories have no license file | packaging-ci.md |
| [NYX-PKG-004](packaging-ci.md#nyx-pkg-004-prebuilt-third-party-binaries-and-a-cuda-path-ci-never-builds) | Prebuilt third-party binaries and a CUDA path CI never builds | packaging-ci.md |
| [NYX-PKG-005](packaging-ci.md#nyx-pkg-005-release-builds-are-stripped-no-debug-symbols-for-crash-reports) | Release builds are stripped; no debug symbols for crash reports | packaging-ci.md |
| [NYX-PKG-006](packaging-ci.md#nyx-pkg-006-runtime-code-still-assumes-host-paths-outside-the-package) | Runtime code still assumes host paths outside the package | packaging-ci.md |
| [NYX-PRIV-003](privacy.md#nyx-priv-003-ip-geolocation-goes-to-a-third-party-ipapico-without-consent) | IP geolocation goes to a third party (ipapi.co) without consent | privacy.md |
| [NYX-PRIV-004](privacy.md#nyx-priv-004-nyx-connect-shares-clipboard-and-notifications-by-default-and-browse-pcs-safe-default-reaches-only-new-configs) | Nyx Connect shares clipboard and notifications by default, and Browse PC's safe default reaches only new configs | privacy.md |
| [NYX-PRIV-005](privacy.md#nyx-priv-005-notification-history-is-readable-by-any-same-user-process-over-d-bus) | Notification history is readable by any same-user process over D-Bus | privacy.md |
| [NYX-PRIV-006](privacy.md#nyx-priv-006-capture-ocr-indexes-every-screenshot-and-keeps-it-for-90-days-by-default) | Capture OCR-indexes every screenshot and keeps it for 90 days by default | privacy.md |
| [NYX-REL-001](reliability.md#nyx-rel-001-the-journal-is-flooded-with-duplicate-d-bus-service-warnings-and-per-launch-qml-warnings) | The journal is flooded with duplicate D-Bus service warnings and per-launch QML warnings | reliability.md |
| [NYX-SEC-009](security.md#nyx-sec-009-ci-pushes-pull-request-builds-to-the-trusted-binary-cache) | CI pushes pull-request builds to the trusted binary cache | security.md |
| [NYX-SEC-010](security.md#nyx-sec-010-biometrics-entry-in-etcnyxtrusted-bin-is-overwritten-by-the-activation-script) | Biometrics' entry in `/etc/nyx/trusted-bin` is overwritten by the activation script | security.md |
| [NYX-SEC-011](security.md#nyx-sec-011-nyx-locker-authenticates-the-user-named-by-user-not-the-sessions-uid) | Nyx Locker authenticates the user named by `$USER`, not the session's uid | security.md |
| [NYX-SEC-012](security.md#nyx-sec-012-system-managers-read-methods-are-open-to-every-local-account) | System Manager's read methods are open to every local account | security.md |
| [NYX-SEC-013](security.md#nyx-sec-013-security-documentation-claims-features-that-dont-ship) | Security documentation claims features that don't ship | security.md |
| [NYX-SEC-014](security.md#nyx-sec-014-nyx-pulse-ships-a-shared-telegram-api-credential-in-source) | Nyx Pulse ships a shared Telegram API credential in source | security.md |
| [NYX-SET-001](infrastructure.md#nyx-set-001-omarchy-wording-leaks-into-nyxos-settings-resets) | Omarchy wording leaks into NyxOS Settings resets | infrastructure.md |
| [NYX-SET-002](infrastructure.md#nyx-set-002-hyprland-settings-bypass-the-administrator-layer-and-there-is-no-settings-ipc) | Hyprland settings bypass the administrator layer, and there is no Settings IPC | infrastructure.md |
| [NYX-SHELL-003](shell.md#nyx-shell-003-glimpse-and-the-panels-can-be-open-together-both-holding-the-keyboard) | Glimpse and the panels can be open together, both holding the keyboard | shell.md |
| [NYX-SHELL-004](shell.md#nyx-shell-004-brightness-osd-is-polled-every-2-seconds-for-the-whole-session) | Brightness OSD is polled every 2 seconds for the whole session | shell.md |
| [NYX-SHELL-006](shell.md#nyx-shell-006-shell-core-asks-hyprland-for-nyxdecor-on-every-desktop-update) | Shell Core asks Hyprland for `nyxdecor` on every desktop update | shell.md |
| [NYX-SHELL-007](shell.md#nyx-shell-007-dock-swipe-following-isnt-active-on-nyxos) | Dock swipe following isn't active on NyxOS | shell.md |
| [NYX-SHELL-008](shell.md#nyx-shell-008-the-default-gtk-aura-doesnt-leave-room-for-nyx-bar) | The default (GTK) Aura doesn't leave room for Nyx Bar | shell.md |
| [NYX-THEME-003](infrastructure.md#nyx-theme-003-a-corrupt-themetoml-is-silently-replaced-losing-overrides-and-token-choices) | A corrupt theme.toml is silently replaced, losing overrides and token choices | infrastructure.md |
| [NYX-THEME-004](infrastructure.md#nyx-theme-004-theme-installation-clones-whole-repositories-with-no-size-or-time-limit) | Theme installation clones whole repositories with no size or time limit | infrastructure.md |
| [NYX-THEME-005](infrastructure.md#nyx-theme-005-stale-nyx-dark-and-omarchy-defaults-remain-beside-the-mocha-default) | Stale Nyx Dark and Omarchy defaults remain beside the Mocha default | infrastructure.md |
| [NYX-UPD-002](infrastructure.md#nyx-upd-002-the-stable-channels-nyx-packages-input-doesnt-follow-nyx-packages-stable) | The stable channel's nyx-packages input doesn't follow nyx-packages' stable | infrastructure.md |
| [NYX-UX-001](ux-accessibility.md#nyx-ux-001-the-launcher-lists-helper-entries-that-open-nothing) | The launcher lists helper entries that open nothing | ux-accessibility.md |
| [NYX-UX-002](ux-accessibility.md#nyx-ux-002-network-failures-show-raw-error-text) | Network failures show raw error text | ux-accessibility.md |
| [NYX-UX-003](ux-accessibility.md#nyx-ux-003-login-screen-polish-wordmark-cut-off-technical-session-name) | Login screen polish: wordmark cut off, technical session name | ux-accessibility.md |
| [NYX-UX-004](ux-accessibility.md#nyx-ux-004-nyx-system-generations-prints-unix-timestamps) | `nyx system generations` prints Unix timestamps | ux-accessibility.md |
| [NYX-VOICE-003](infrastructure.md#nyx-voice-003-chat-keeps-its-own-speech-stack-instead-of-nyx-voice) | Chat keeps its own speech stack instead of Nyx Voice | infrastructure.md |

